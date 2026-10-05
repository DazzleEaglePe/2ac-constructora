import { HttpStatus, Injectable } from '@nestjs/common';
import { AssetStatus, MovementKind, Prisma, SiteStatus } from '@prisma/client';
import { DomainException } from '../../common/filters/problem-details.filter';
import { PrismaService } from '../../prisma/prisma.service';
import type { AuthUser } from '../auth/auth.types';
import type { CreateMovementDto, ListMovementsQuery } from './dto/movements.dto';

const includeMovement = {
  asset: { select: { id: true, code: true, name: true, type: true, status: true } },
  fromSite: { select: { id: true, name: true, type: true } },
  toSite: { select: { id: true, name: true, type: true } },
  user: { select: { id: true, fullName: true } },
  observation: true,
} satisfies Prisma.MovementInclude;

const fail = (code: string, message: string, status: HttpStatus) =>
  new DomainException(code, message, status);

@Injectable()
export class MovementsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreateMovementDto, idempotencyKey: string, actor: AuthUser) {
    if (dto.fromSiteId === dto.toSiteId) {
      throw fail('ORIGEN_IGUAL_DESTINO', 'El origen y el destino deben ser distintos', HttpStatus.UNPROCESSABLE_ENTITY);
    }
    const repeated = await this.prisma.movement.findUnique({
      where: { userId_idempotencyKey: { userId: actor.id, idempotencyKey } },
      include: includeMovement,
    });
    if (repeated) return this.replayOrConflict(repeated, dto, this.prisma);

    return this.prisma.$transaction(async (tx) => {
      await tx.$queryRaw<{ locked: boolean }[]>`SELECT pg_advisory_xact_lock(hashtextextended(${`${actor.id}:${idempotencyKey}`}, 1)) IS NULL AS locked`;
      // Serializa todos los cambios de distribución de este activo, también cuando el destino aún no tiene fila de stock.
      await tx.$queryRaw<{ locked: boolean }[]>`SELECT pg_advisory_xact_lock(hashtextextended(${dto.assetId}, 0)) IS NULL AS locked`;
      const repeatedInTransaction = await tx.movement.findUnique({
        where: { userId_idempotencyKey: { userId: actor.id, idempotencyKey } },
        include: includeMovement,
      });
      if (repeatedInTransaction) return this.replayOrConflict(repeatedInTransaction, dto, tx);
      const [asset, fromSite, toSite] = await Promise.all([
        tx.asset.findUnique({ where: { id: dto.assetId } }),
        tx.site.findUnique({ where: { id: dto.fromSiteId } }),
        tx.site.findUnique({ where: { id: dto.toSiteId } }),
      ]);
      if (!asset) throw fail('NO_ENCONTRADO', 'Activo no encontrado', HttpStatus.NOT_FOUND);
      if (!fromSite || !toSite) throw fail('NO_ENCONTRADO', 'Obra o almacén no encontrado', HttpStatus.NOT_FOUND);
      if (toSite.status !== SiteStatus.ACTIVA) {
        throw fail('OBRA_CERRADA', 'El destino está cerrado y no puede recibir activos', HttpStatus.CONFLICT);
      }
      if (asset.status === AssetStatus.BAJA) {
        throw fail('ACTIVO_DE_BAJA', 'Un activo dado de baja no se puede mover', HttpStatus.CONFLICT);
      }
      if (asset.type === 'MAQUINA' && dto.quantity !== 1) {
        throw fail('MAQUINA_UNIDAD_UNICA', 'Una máquina se mueve de una en una', HttpStatus.UNPROCESSABLE_ENTITY);
      }
      const source = await tx.stock.findUnique({
        where: { assetId_siteId: { assetId: dto.assetId, siteId: dto.fromSiteId } },
      });
      if (!source || source.quantity < dto.quantity) {
        throw fail('STOCK_INSUFICIENTE', 'No hay suficiente stock en el origen', HttpStatus.CONFLICT);
      }
      const movement = await tx.movement.create({
        data: {
          kind: MovementKind.TRASLADO,
          assetId: dto.assetId,
          fromSiteId: dto.fromSiteId,
          toSiteId: dto.toSiteId,
          quantity: dto.quantity,
          userId: actor.id,
          note: dto.note,
          idempotencyKey,
          ...(dto.observation ? {
            observation: {
              create: {
                assetId: dto.assetId,
                type: dto.observation.type,
                description: dto.observation.description,
              },
            },
          } : {}),
        },
      });
      const sourceAfter = source.quantity - dto.quantity;
      await tx.stock.update({
        where: { assetId_siteId: { assetId: dto.assetId, siteId: dto.fromSiteId } },
        data: { quantity: { decrement: dto.quantity } },
      });
      const destination = await tx.stock.upsert({
        where: { assetId_siteId: { assetId: dto.assetId, siteId: dto.toSiteId } },
        create: { assetId: dto.assetId, siteId: dto.toSiteId, quantity: dto.quantity },
        update: { quantity: { increment: dto.quantity } },
      });
      const full = await tx.movement.findUniqueOrThrow({ where: { id: movement.id }, include: includeMovement });
      return {
        ...full,
        stockAfter: { from: sourceAfter, to: destination.quantity },
      };
    });
  }

  async list(query: ListMovementsQuery) {
    const rows = await this.prisma.movement.findMany({
      where: {
        assetId: query.assetId,
        userId: query.userId,
        ...(query.siteId ? { OR: [{ fromSiteId: query.siteId }, { toSiteId: query.siteId }] } : {}),
        ...(query.from || query.to ? { createdAt: {
          ...(query.from ? { gte: new Date(query.from) } : {}),
          ...(query.to ? { lte: new Date(query.to) } : {}),
        } } : {}),
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: 100,
      include: includeMovement,
    });
    return rows;
  }

  async get(id: string) {
    const movement = await this.prisma.movement.findUnique({ where: { id }, include: includeMovement });
    if (!movement) throw fail('NO_ENCONTRADO', 'Movimiento no encontrado', HttpStatus.NOT_FOUND);
    return movement;
  }

  private replayOrConflict(
    movement: Prisma.MovementGetPayload<{ include: typeof includeMovement }>,
    dto: CreateMovementDto,
    client: PrismaService | Prisma.TransactionClient,
  ) {
    const same = movement.kind === MovementKind.TRASLADO &&
      movement.assetId === dto.assetId && movement.fromSiteId === dto.fromSiteId &&
      movement.toSiteId === dto.toSiteId && movement.quantity === dto.quantity &&
      movement.note === (dto.note ?? null) &&
      movement.observation?.type === (dto.observation?.type ?? undefined) &&
      movement.observation?.description === (dto.observation?.description ?? undefined);
    if (!same) throw fail('IDEMPOTENCIA_CONFLICTO', 'La clave ya se usó con otro movimiento', HttpStatus.CONFLICT);
    return this.withStockAfter(movement, client);
  }

  private async withStockAfter(
    movement: Prisma.MovementGetPayload<{ include: typeof includeMovement }>,
    client: PrismaService | Prisma.TransactionClient,
  ) {
    if (!movement.fromSiteId || !movement.toSiteId) return movement;
    const ledger = await client.movement.findMany({
      where: { assetId: movement.assetId, createdAt: { lte: movement.createdAt } },
      select: { fromSiteId: true, toSiteId: true, quantity: true },
    });
    const stock = new Map<string, number>();
    for (const row of ledger) {
      if (row.fromSiteId) stock.set(row.fromSiteId, (stock.get(row.fromSiteId) ?? 0) - row.quantity);
      if (row.toSiteId) stock.set(row.toSiteId, (stock.get(row.toSiteId) ?? 0) + row.quantity);
    }
    return {
      ...movement,
      stockAfter: {
        from: stock.get(movement.fromSiteId) ?? 0,
        to: stock.get(movement.toSiteId) ?? 0,
      },
    };
  }
}
