import { HttpStatus, Injectable } from '@nestjs/common';
import { Prisma, SiteStatus, SiteType } from '@prisma/client';
import { DomainException } from '../../common/filters/problem-details.filter';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { RealtimeGateway } from '../realtime/realtime.gateway';
import type { AuthUser } from '../auth/auth.types';
import type { CreateSiteDto, ListSitesQuery, SiteStockQuery, UpdateSiteDto } from './dto/sites.dto';
import { toSiteView, type SiteSummary, type SiteView } from './site.view';

const notFound = () => new DomainException('NO_ENCONTRADO', 'Obra no encontrada', HttpStatus.NOT_FOUND);

@Injectable()
export class SitesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly realtime: RealtimeGateway,
  ) {}

  async list(query: ListSitesQuery): Promise<SiteView[]> {
    const where: Prisma.SiteWhereInput = {
      type: query.type,
      status: query.status,
      ...(query.q
        ? {
            OR: [
              { name: { contains: query.q, mode: 'insensitive' } },
              { ownerName: { contains: query.q, mode: 'insensitive' } },
              { address: { contains: query.q, mode: 'insensitive' } },
            ],
          }
        : {}),
    };
    const sites = await this.prisma.site.findMany({
      where,
      orderBy: [{ type: 'asc' }, { status: 'asc' }, { name: 'asc' }],
      take: 100,
    });
    const summaries = await this.summaries(sites.map((site) => site.id));
    return sites.map((site) => toSiteView(site, summaries.get(site.id)!));
  }

  async get(id: string): Promise<SiteView> {
    const site = await this.prisma.site.findUnique({ where: { id } });
    if (!site) throw notFound();
    const summaries = await this.summaries([id]);
    return toSiteView(site, summaries.get(id)!);
  }

  async create(dto: CreateSiteDto, actor: AuthUser, ip?: string): Promise<SiteView> {
    if ((dto.lat === undefined) !== (dto.lng === undefined)) {
      throw new DomainException(
        'VALIDACION',
        'Latitud y longitud deben enviarse juntas',
        HttpStatus.UNPROCESSABLE_ENTITY,
      );
    }
    const site = await this.prisma.$transaction(async (tx) => {
      const created = await tx.site.create({
        data: {
          type: SiteType.OBRA,
          name: dto.name,
          ownerName: dto.ownerName,
          address: dto.address,
          lat: dto.lat,
          lng: dto.lng,
        },
      });
      await this.audit.log(
        {
          userId: actor.id,
          action: 'SITE_CREATED',
          entityType: 'site',
          entityId: created.id,
          after: snapshot(created),
          ip,
        },
        tx,
      );
      return created;
    });
    this.realtime.publish('site.updated', { id: site.id, updatedAt: site.updatedAt.toISOString() });
    return toSiteView(site, emptySummary());
  }

  async update(id: string, dto: UpdateSiteDto, actor: AuthUser, ip?: string): Promise<SiteView> {
    if ((dto.lat === undefined) !== (dto.lng === undefined)) {
      throw new DomainException(
        'VALIDACION',
        'Latitud y longitud deben actualizarse juntas',
        HttpStatus.UNPROCESSABLE_ENTITY,
      );
    }
    const before = await this.findOrThrow(id);
    const site = await this.prisma.$transaction(async (tx) => {
      const updated = await tx.site.update({
        where: { id },
        data: {
          name: dto.name,
          ownerName: dto.ownerName,
          address: dto.address,
          lat: dto.lat,
          lng: dto.lng,
        },
      });
      await this.audit.log(
        {
          userId: actor.id,
          action: 'SITE_UPDATED',
          entityType: 'site',
          entityId: id,
          before: snapshot(before),
          after: snapshot(updated),
          ip,
        },
        tx,
      );
      return updated;
    });
    this.realtime.publish('site.updated', { id: site.id, updatedAt: site.updatedAt.toISOString() });
    const summaries = await this.summaries([id]);
    return toSiteView(site, summaries.get(id)!);
  }

  async close(id: string, actor: AuthUser, ip?: string): Promise<SiteView> {
    const site = await this.prisma.$transaction(async (tx) => {
      await tx.$queryRaw`SELECT id FROM sites WHERE id = ${id}::uuid FOR UPDATE`;
      const before = await tx.site.findUnique({ where: { id } });
      if (!before) throw notFound();
      if (before.type === SiteType.ALMACEN) {
        throw new DomainException('OBRA_CERRADA', 'El almacén central no se puede cerrar', HttpStatus.CONFLICT);
      }
      if (before.status === SiteStatus.CERRADA) return before;
      const stock = await tx.stock.aggregate({ where: { siteId: id }, _sum: { quantity: true } });
      if ((stock._sum.quantity ?? 0) > 0) {
        throw new DomainException(
          'OBRA_CERRADA',
          'No se puede cerrar la obra mientras tenga activos asignados',
          HttpStatus.CONFLICT,
        );
      }
      const updated = await tx.site.update({ where: { id }, data: { status: SiteStatus.CERRADA } });
      await this.audit.log(
        {
          userId: actor.id,
          action: 'SITE_CLOSED',
          entityType: 'site',
          entityId: id,
          before: snapshot(before),
          after: snapshot(updated),
          ip,
        },
        tx,
      );
      return updated;
    });
    this.realtime.publish('site.updated', { id: site.id, updatedAt: site.updatedAt.toISOString() });
    const summaries = await this.summaries([id]);
    return toSiteView(site, summaries.get(id)!);
  }

  async reopen(id: string, actor: AuthUser, ip?: string): Promise<SiteView> {
    const site = await this.prisma.$transaction(async (tx) => {
      await tx.$queryRaw`SELECT id FROM sites WHERE id = ${id}::uuid FOR UPDATE`;
      const before = await tx.site.findUnique({ where: { id } });
      if (!before) throw notFound();
      if (before.type === SiteType.ALMACEN) {
        throw new DomainException('OBRA_CERRADA', 'El almacén central no necesita reabrirse', HttpStatus.CONFLICT);
      }
      if (before.status === SiteStatus.ACTIVA) return before;
      const updated = await tx.site.update({ where: { id }, data: { status: SiteStatus.ACTIVA } });
      await this.audit.log(
        {
          userId: actor.id,
          action: 'SITE_REOPENED',
          entityType: 'site',
          entityId: id,
          before: snapshot(before),
          after: snapshot(updated),
          ip,
        },
        tx,
      );
      return updated;
    });
    this.realtime.publish('site.updated', { id: site.id, updatedAt: site.updatedAt.toISOString() });
    const summaries = await this.summaries([id]);
    return toSiteView(site, summaries.get(id)!);
  }

  async stock(id: string, query: SiteStockQuery) {
    await this.findOrThrow(id);
    return this.prisma.stock.findMany({
      where: { siteId: id, quantity: { gt: 0 }, asset: { type: query.type } },
      orderBy: [{ asset: { name: 'asc' } }],
      select: {
        quantity: true,
        asset: { select: { id: true, code: true, type: true, name: true, status: true } },
      },
    }).then((rows) => rows.map((row) => ({ ...row.asset, quantity: row.quantity })));
  }

  private async findOrThrow(id: string) {
    const site = await this.prisma.site.findUnique({ where: { id } });
    if (!site) throw notFound();
    return site;
  }

  private async summaries(siteIds: string[]): Promise<Map<string, SiteSummary>> {
    const result = new Map(siteIds.map((id) => [id, emptySummary()]));
    if (!siteIds.length) return result;

    const [stocks, fromMovements, toMovements] = await Promise.all([
      this.prisma.stock.findMany({
        where: { siteId: { in: siteIds }, quantity: { gt: 0 } },
        select: { siteId: true, assetId: true, quantity: true, asset: { select: { name: true } } },
      }),
      this.prisma.movement.groupBy({
        by: ['fromSiteId'],
        where: { fromSiteId: { in: siteIds } },
        _max: { createdAt: true },
      }),
      this.prisma.movement.groupBy({
        by: ['toSiteId'],
        where: { toSiteId: { in: siteIds } },
        _max: { createdAt: true },
      }),
    ]);
    const itemCounts = new Map<string, Map<string, number>>();
    const assetCounts = new Map<string, Set<string>>();
    for (const row of stocks) {
      const summary = result.get(row.siteId)!;
      summary.units += row.quantity;
      const assets = assetCounts.get(row.siteId) ?? new Set<string>();
      assets.add(row.assetId);
      assetCounts.set(row.siteId, assets);
      const items = itemCounts.get(row.siteId) ?? new Map<string, number>();
      items.set(row.asset.name, (items.get(row.asset.name) ?? 0) + row.quantity);
      itemCounts.set(row.siteId, items);
    }
    for (const [siteId, assets] of assetCounts) result.get(siteId)!.assetCount = assets.size;
    for (const [siteId, items] of itemCounts) {
      result.get(siteId)!.topItems = [...items].map(([name, quantity]) => ({ name, quantity }))
        .sort((a, b) => b.quantity - a.quantity || a.name.localeCompare(b.name, 'es'))
        .slice(0, 3);
    }
    const applyLastMovement = (siteId: string | null, date: Date | null) => {
      if (!siteId || !date) return;
      const summary = result.get(siteId)!;
      if (!summary.lastMovementAt || date > summary.lastMovementAt) summary.lastMovementAt = date;
    };
    for (const row of fromMovements) applyLastMovement(row.fromSiteId, row._max.createdAt);
    for (const row of toMovements) applyLastMovement(row.toSiteId, row._max.createdAt);
    return result;
  }
}

const emptySummary = (): SiteSummary => ({ units: 0, assetCount: 0, lastMovementAt: null, topItems: [] });
const snapshot = (site: { type: SiteType; name: string; ownerName: string | null; address: string | null; lat: Prisma.Decimal | null; lng: Prisma.Decimal | null; status: SiteStatus }) => ({
  type: site.type,
  name: site.name,
  ownerName: site.ownerName,
  address: site.address,
  lat: site.lat === null ? null : Number(site.lat),
  lng: site.lng === null ? null : Number(site.lng),
  status: site.status,
});
