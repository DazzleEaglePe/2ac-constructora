import { HttpStatus, Injectable } from '@nestjs/common';
import { ObservationStatus, Prisma } from '@prisma/client';
import { DomainException } from '../../common/filters/problem-details.filter';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import type { AuthUser } from '../auth/auth.types';
import type { ListObservationsQuery, ResolveObservationDto } from './dto/movements.dto';

const notFound = () => new DomainException('NO_ENCONTRADO', 'Observación no encontrada', HttpStatus.NOT_FOUND);
const includeObservation = {
  asset: { select: { id: true, code: true, name: true } },
  movement: { select: { id: true, createdAt: true, fromSite: { select: { id: true, name: true } }, toSite: { select: { id: true, name: true } } } },
  resolvedBy: { select: { id: true, fullName: true } },
} satisfies Prisma.MovementObservationInclude;

@Injectable()
export class ObservationsService {
  constructor(private readonly prisma: PrismaService, private readonly audit: AuditService) {}

  list(query: ListObservationsQuery) {
    return this.prisma.movementObservation.findMany({
      where: { status: query.status, assetId: query.assetId },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: 100,
      include: includeObservation,
    });
  }

  async resolve(id: string, dto: ResolveObservationDto, actor: AuthUser, ip?: string) {
    return this.prisma.$transaction(async (tx) => {
      const before = await tx.movementObservation.findUnique({ where: { id } });
      if (!before) throw notFound();
      if (before.status !== ObservationStatus.ABIERTA) {
        throw new DomainException('OBSERVACION_ATENDIDA', 'La observación ya fue atendida', HttpStatus.CONFLICT);
      }
      const changed = await tx.movementObservation.updateMany({
        where: { id, status: ObservationStatus.ABIERTA },
        data: {
          status: ObservationStatus.ATENDIDA,
          resolvedById: actor.id,
          resolvedAt: new Date(),
          resolution: dto.resolution,
        },
      });
      if (changed.count !== 1) {
        throw new DomainException('OBSERVACION_ATENDIDA', 'La observación ya fue atendida', HttpStatus.CONFLICT);
      }
      const updated = await tx.movementObservation.findUniqueOrThrow({ where: { id }, include: includeObservation });
      await this.audit.log({
        userId: actor.id,
        action: 'OBSERVATION_RESOLVED',
        entityType: 'asset',
        entityId: before.assetId,
        before: { observationId: id, status: before.status },
        after: { observationId: id, status: updated.status, resolution: updated.resolution },
        ip,
      }, tx);
      return updated;
    });
  }
}
