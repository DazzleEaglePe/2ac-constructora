import { Injectable } from '@nestjs/common';
import { ObservationStatus, SiteType } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { SitesService } from '../sites/sites.service';
import type { DashboardQuery } from './dashboard.dto';

@Injectable()
export class DashboardService {
  constructor(private readonly prisma: PrismaService, private readonly sitesService: SitesService) {}

  async get(query: DashboardQuery) {
    const allSites = await this.sitesService.list({});
    const sites = allSites.filter((site) => site.type === SiteType.OBRA);
    const warehouse = allSites.find((site) => site.type === SiteType.ALMACEN) ?? null;
    const projectIds = sites.map((site) => site.id);
    const [units, assetsInMaintenance, openObservations, latestMovement, latestSite, latestAsset, latestStock, latestAudit] = await Promise.all([
      this.prisma.stock.aggregate({ where: { siteId: { in: projectIds } }, _sum: { quantity: true } }),
      this.prisma.asset.count({ where: { status: 'MANTENIMIENTO' } }),
      this.prisma.movementObservation.count({ where: { status: ObservationStatus.ABIERTA } }),
      this.prisma.movement.findFirst({ orderBy: { createdAt: 'desc' }, select: { createdAt: true } }),
      this.prisma.site.aggregate({ _max: { updatedAt: true } }),
      this.prisma.asset.aggregate({ _max: { updatedAt: true } }),
      this.prisma.stock.aggregate({ _max: { updatedAt: true } }),
      this.prisma.auditLog.aggregate({ _max: { createdAt: true } }),
    ]);
    const latest = [latestMovement?.createdAt, latestSite._max.updatedAt, latestAsset._max.updatedAt, latestStock._max.updatedAt, latestAudit._max.createdAt]
      .filter((date): date is Date => date !== null && date !== undefined)
      .reduce<Date | null>((current, date) => current === null || date > current ? date : current, null);
    const since = query.since ? new Date(query.since) : null;
    return {
      generatedAt: new Date(),
      totals: {
        unitsOnSites: units._sum.quantity ?? 0,
        assetsInMaintenance,
        activeSites: sites.filter((site) => site.status === 'ACTIVA').length,
        warehouseUnits: warehouse?.summary.units ?? 0,
        openObservations,
      },
      sites,
      warehouse,
      changedSince: since === null || (latest !== null && latest > since),
    };
  }
}
