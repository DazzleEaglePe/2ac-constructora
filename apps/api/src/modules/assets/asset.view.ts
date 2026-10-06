import type { Asset, AssetStatus, AssetType } from '@prisma/client';

export interface AssetDistribution {
  siteId: string;
  siteName: string;
  siteType: string;
  quantity: number;
}

export interface AssetView {
  id: string;
  code: string;
  type: AssetType;
  name: string;
  description: string | null;
  status: AssetStatus;
  totalStock: number;
  distribution: AssetDistribution[];
  notesCount: number;
  updatedAt: Date;
}

export const toAssetView = (
  asset: Asset & { stock: { quantity: number; site: { id: string; name: string; type: string } }[]; _count?: { notes: number } },
): AssetView => ({
  id: asset.id,
  code: asset.code,
  type: asset.type,
  name: asset.name,
  description: asset.description,
  status: asset.status,
  totalStock: asset.totalStock,
  distribution: asset.stock
    .filter((row) => row.quantity > 0)
    .map((row) => ({
      siteId: row.site.id,
      siteName: row.site.name,
      siteType: row.site.type,
      quantity: row.quantity,
    })),
  notesCount: asset._count?.notes ?? 0,
  updatedAt: asset.updatedAt,
});
