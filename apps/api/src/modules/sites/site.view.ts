import type { Site, SiteStatus, SiteType } from '@prisma/client';

export interface SiteSummary {
  units: number;
  assetCount: number;
  lastMovementAt: Date | null;
  topItems: Array<{ name: string; quantity: number }>;
}

export interface SiteView {
  id: string;
  type: SiteType;
  name: string;
  ownerName: string | null;
  address: string | null;
  lat: number | null;
  lng: number | null;
  status: SiteStatus;
  createdAt: Date;
  updatedAt: Date;
  summary: SiteSummary;
}

export const toSiteView = (site: Site, summary: SiteSummary): SiteView => ({
  id: site.id,
  type: site.type,
  name: site.name,
  ownerName: site.ownerName,
  address: site.address,
  lat: site.lat === null ? null : Number(site.lat),
  lng: site.lng === null ? null : Number(site.lng),
  status: site.status,
  createdAt: site.createdAt,
  updatedAt: site.updatedAt,
  summary,
});

