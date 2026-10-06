import { HttpStatus, Injectable } from '@nestjs/common';
import { AssetStatus, AssetType, MovementKind, Prisma, SiteStatus } from '@prisma/client';
import { DomainException } from '../../common/filters/problem-details.filter';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { RealtimeGateway } from '../realtime/realtime.gateway';
import type { AuthUser } from '../auth/auth.types';
import type {
  ChangeAssetStatusDto,
  CreateAssetDto,
  CreateAssetNoteDto,
  ListAssetsQuery,
  SearchAssetsQuery,
  UpdateAssetDto,
} from './dto/assets.dto';
import { toAssetView, type AssetView } from './asset.view';

const notFound = () =>
  new DomainException('NO_ENCONTRADO', 'Activo no encontrado', HttpStatus.NOT_FOUND);
const includeAsset = {
  stock: { include: { site: { select: { id: true, name: true, type: true } } } },
  _count: { select: { notes: true } },
} satisfies Prisma.AssetInclude;

@Injectable()
export class AssetsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly realtime: RealtimeGateway,
  ) {}

  async list(query: ListAssetsQuery): Promise<AssetView[]> {
    return (await this.search({ ...query, limit: 200 })).data;
  }

  async search(query: SearchAssetsQuery) {
    const limit = query.limit ?? 50;
    const cursor = query.cursor
      ? await this.prisma.asset.findUnique({
          where: { id: query.cursor },
          select: { id: true, name: true, code: true },
        })
      : null;
    const search = query.q
      ? Prisma.sql`AND (
          lower(immutable_unaccent(a.name)) LIKE lower(immutable_unaccent(${`%${query.q}%`}))
          OR lower(a.code) LIKE lower(${`%${query.q}%`})
        )`
      : Prisma.empty;
    const type = query.type ? Prisma.sql`AND a.type = ${query.type}::"AssetType"` : Prisma.empty;
    const status = query.status
      ? Prisma.sql`AND a.status = ${query.status}::"AssetStatus"`
      : Prisma.empty;
    const site = query.siteId
      ? Prisma.sql`AND EXISTS (
          SELECT 1 FROM stock AS s
          WHERE s.asset_id = a.id AND s.site_id = ${query.siteId}::uuid AND s.quantity > 0
        )`
      : Prisma.empty;
    const after = cursor
      ? Prisma.sql`AND (
          lower(immutable_unaccent(a.name)), lower(a.code), a.id
        ) > (
          lower(immutable_unaccent(${cursor.name})), lower(${cursor.code}), ${cursor.id}::uuid
        )`
      : Prisma.empty;
    const candidates = await this.prisma.$queryRaw<{ id: string }[]>(Prisma.sql`
      SELECT a.id
      FROM assets AS a
      WHERE true ${search} ${type} ${status} ${site} ${after}
      ORDER BY lower(immutable_unaccent(a.name)), lower(a.code), a.id
      LIMIT ${limit + 1}
    `);
    const hasMore = candidates.length > limit;
    const pageIds = candidates.slice(0, limit).map(({ id }) => id);
    const assets = pageIds.length
      ? await this.prisma.asset.findMany({
          where: { id: { in: pageIds } },
          include: includeAsset,
        })
      : [];
    const byId = new Map(assets.map((asset) => [asset.id, asset]));
    const data = pageIds.flatMap((id) => {
      const asset = byId.get(id);
      return asset ? [toAssetView(asset)] : [];
    });
    return {
      data,
      nextCursor: hasMore ? (pageIds[pageIds.length - 1] ?? null) : null,
    };
  }

  async get(id: string): Promise<AssetView> {
    const asset = await this.prisma.asset.findUnique({ where: { id }, include: includeAsset });
    if (!asset) throw notFound();
    return toAssetView(asset);
  }

  async nextCode(type: AssetType): Promise<{ code: string }> {
    const prefix = prefixFor(type);
    const sequence = await this.prisma.codeSequence.findUnique({ where: { prefix } });
    return { code: makeCode(prefix, (sequence?.lastValue ?? 0) + 1) };
  }

  async create(
    dto: CreateAssetDto,
    idempotencyKey: string,
    actor: AuthUser,
    ip?: string,
  ): Promise<AssetView> {
    if (dto.type === AssetType.MAQUINA && dto.initialQuantity !== 1) {
      throw new DomainException(
        'VALIDACION',
        'Una máquina debe tener stock inicial de una unidad',
        HttpStatus.UNPROCESSABLE_ENTITY,
      );
    }
    const repeated = await this.findByIdempotency(actor.id, idempotencyKey);
    if (repeated) return this.get(repeated.assetId);

    const site = await this.prisma.site.findUnique({ where: { id: dto.initialSiteId } });
    if (!site || site.status !== SiteStatus.ACTIVA) {
      throw new DomainException(
        'NO_ENCONTRADO',
        'La ubicación inicial no existe o está cerrada',
        HttpStatus.UNPROCESSABLE_ENTITY,
      );
    }
    const prefix = prefixFor(dto.type);
    try {
      const asset = await this.prisma.$transaction(async (tx) => {
        const [sequence] = await tx.$queryRaw<{ last_value: number }[]>`
          INSERT INTO code_sequences (prefix, last_value)
          VALUES (${prefix}, 1)
          ON CONFLICT (prefix) DO UPDATE SET last_value = code_sequences.last_value + 1
          RETURNING last_value
        `;
        const totalStock = dto.type === AssetType.MAQUINA ? 1 : dto.initialQuantity;
        const created = await tx.asset.create({
          data: {
            code: makeCode(prefix, sequence.last_value),
            type: dto.type,
            name: dto.name,
            description: dto.description,
            status: dto.status ?? AssetStatus.OPERATIVO,
            totalStock,
            stock: { create: { siteId: site.id, quantity: totalStock } },
            movements: {
              create: {
                kind: MovementKind.ALTA,
                toSiteId: site.id,
                quantity: totalStock,
                userId: actor.id,
                idempotencyKey,
                note: 'Alta inicial',
              },
            },
          },
          include: includeAsset,
        });
        await this.audit.log(
          {
            userId: actor.id,
            action: 'ASSET_CREATED',
            entityType: 'asset',
            entityId: created.id,
            after: snapshot(created),
            ip,
          },
          tx,
        );
        return created;
      });
      const view = toAssetView(asset);
      this.realtime.publish('asset.updated', {
        id: view.id,
        updatedAt: asset.updatedAt.toISOString(),
      });
      this.realtime.publish('stock.updated', {
        assetId: view.id,
        siteIds: view.distribution.map((row) => row.siteId),
      });
      return view;
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
        const duplicate = await this.findByIdempotency(actor.id, idempotencyKey);
        if (duplicate) return this.get(duplicate.assetId);
      }
      throw error;
    }
  }

  async update(id: string, dto: UpdateAssetDto, actor: AuthUser, ip?: string): Promise<AssetView> {
    const before = await this.prisma.asset.findUnique({ where: { id }, include: includeAsset });
    if (!before) throw notFound();
    const asset = await this.prisma.$transaction(async (tx) => {
      const updated = await tx.asset.update({ where: { id }, data: dto, include: includeAsset });
      await this.audit.log(
        {
          userId: actor.id,
          action: 'ASSET_UPDATED',
          entityType: 'asset',
          entityId: id,
          before: snapshot(before),
          after: snapshot(updated),
          ip,
        },
        tx,
      );
      return updated;
    });
    const view = toAssetView(asset);
    this.realtime.publish('asset.updated', {
      id: view.id,
      updatedAt: asset.updatedAt.toISOString(),
    });
    return view;
  }

  async changeStatus(
    id: string,
    dto: ChangeAssetStatusDto,
    actor: AuthUser,
    ip?: string,
  ): Promise<AssetView> {
    if (dto.status === AssetStatus.BAJA && !dto.reason?.trim()) {
      throw new DomainException(
        'VALIDACION',
        'Indica el motivo de la baja',
        HttpStatus.UNPROCESSABLE_ENTITY,
      );
    }
    const before = await this.prisma.asset.findUnique({ where: { id }, include: includeAsset });
    if (!before) throw notFound();
    const asset = await this.prisma.$transaction(async (tx) => {
      const updated = await tx.asset.update({
        where: { id },
        data: { status: dto.status },
        include: includeAsset,
      });
      await this.audit.log(
        {
          userId: actor.id,
          action: 'ASSET_STATUS_CHANGED',
          entityType: 'asset',
          entityId: id,
          before: snapshot(before),
          after: { ...snapshot(updated), reason: dto.reason ?? null },
          ip,
        },
        tx,
      );
      return updated;
    });
    const view = toAssetView(asset);
    this.realtime.publish('asset.updated', {
      id: view.id,
      updatedAt: asset.updatedAt.toISOString(),
    });
    return view;
  }

  async notes(id: string) {
    await this.assertExists(id);
    return this.prisma.assetNote
      .findMany({
        where: { assetId: id },
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        take: 100,
        include: { user: { select: { fullName: true } } },
      })
      .then((rows) => rows.map(({ user, ...note }) => ({ ...note, userName: user.fullName })));
  }

  async addNote(id: string, dto: CreateAssetNoteDto, actor: AuthUser, ip?: string) {
    await this.assertExists(id);
    return this.prisma.$transaction(async (tx) => {
      const note = await tx.assetNote.create({
        data: { assetId: id, userId: actor.id, body: dto.body },
        include: { user: { select: { fullName: true } } },
      });
      await this.audit.log(
        {
          userId: actor.id,
          action: 'ASSET_NOTE_ADDED',
          entityType: 'asset',
          entityId: id,
          after: { noteId: note.id, body: note.body },
          ip,
        },
        tx,
      );
      const { user, ...view } = note;
      return { ...view, userName: user.fullName };
    });
  }

  private findByIdempotency(userId: string, idempotencyKey: string) {
    return this.prisma.movement.findUnique({
      where: { userId_idempotencyKey: { userId, idempotencyKey } },
      select: { assetId: true },
    });
  }

  private async assertExists(id: string) {
    if (!(await this.prisma.asset.findUnique({ where: { id }, select: { id: true } })))
      throw notFound();
  }
}

const prefixFor = (type: AssetType) => (type === AssetType.MAQUINA ? 'MAQ' : 'HER');
const makeCode = (prefix: string, value: number) => `${prefix}-${String(value).padStart(4, '0')}`;
const snapshot = (asset: {
  code: string;
  type: AssetType;
  name: string;
  description: string | null;
  status: AssetStatus;
  totalStock: number;
}) => ({
  code: asset.code,
  type: asset.type,
  name: asset.name,
  description: asset.description,
  status: asset.status,
  totalStock: asset.totalStock,
});
