import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

export interface InventoryIntegrityReport {
  checkedAt: string;
  assetStockMismatches: {
    assetId: string;
    code: string;
    expected: number;
    actual: number;
  }[];
  closedSiteStock: {
    siteId: string;
    siteName: string;
    units: number;
  }[];
}

@Injectable()
export class InventoryIntegrityService {
  private readonly logger = new Logger(InventoryIntegrityService.name);

  constructor(private readonly prisma: PrismaService) {}

  @Cron('0 0 2 * * *', {
    name: 'inventory-invariants-nightly',
    timeZone: 'America/Lima',
    waitForCompletion: true,
  })
  async verifyNightly(): Promise<void> {
    try {
      const report = await this.inspect();
      const mismatchCount =
        report.assetStockMismatches.length + report.closedSiteStock.length;
      if (mismatchCount > 0) {
        this.logger.error({
          event: 'inventory.invariants.failed',
          ...report,
        });
        return;
      }
      this.logger.log({
        event: 'inventory.invariants.ok',
        checkedAt: report.checkedAt,
      });
    } catch (error) {
      this.logger.error({
        event: 'inventory.invariants.error',
        error: error instanceof Error ? error.message : String(error),
      });
    }
  }

  async inspect(): Promise<InventoryIntegrityReport> {
    const [assetStockMismatches, closedSiteStock] = await Promise.all([
      this.prisma.$queryRaw<InventoryIntegrityReport['assetStockMismatches']>(Prisma.sql`
        SELECT
          a.id AS "assetId",
          a.code AS code,
          a.total_stock AS expected,
          COALESCE(SUM(s.quantity), 0)::int AS actual
        FROM assets a
        LEFT JOIN stock s ON s.asset_id = a.id
        GROUP BY a.id, a.code, a.total_stock
        HAVING a.total_stock <> COALESCE(SUM(s.quantity), 0)
        ORDER BY a.code
      `),
      this.prisma.$queryRaw<InventoryIntegrityReport['closedSiteStock']>(Prisma.sql`
        SELECT
          sites.id AS "siteId",
          sites.name AS "siteName",
          SUM(stock.quantity)::int AS units
        FROM sites
        INNER JOIN stock ON stock.site_id = sites.id
        WHERE sites.status = 'CERRADA'::"SiteStatus"
          AND stock.quantity > 0
        GROUP BY sites.id, sites.name
        ORDER BY sites.name
      `),
    ]);
    return {
      checkedAt: new Date().toISOString(),
      assetStockMismatches,
      closedSiteStock,
    };
  }
}
