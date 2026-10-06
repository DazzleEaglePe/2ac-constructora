import { INestApplication } from '@nestjs/common';
import { AssetStatus, AssetType, MovementKind, ObservationType, Role, SiteType } from '@prisma/client';
import request from 'supertest';
import { PrismaService } from '../src/prisma/prisma.service';
import { createTestApp, loginOk, seedUser } from './helpers';

describe('Panel y auditoría — RF-PAN / RF-AUD', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let admin: Awaited<ReturnType<typeof seedUser>>;
  let auth: { Authorization: string };
  const api = () => request(app.getHttpServer());

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    admin = await seedUser(app, { role: Role.ADMIN });
    const session = await loginOk(app, admin.dni, admin.password);
    auth = { Authorization: `Bearer ${session.accessToken}` };
    const warehouse = await prisma.site.create({ data: { type: SiteType.ALMACEN, name: 'Almacén dashboard QA' } });
    const site = await prisma.site.create({ data: { type: SiteType.OBRA, name: 'Obra dashboard QA', ownerName: 'Equipo QA' } });
    const asset = await prisma.asset.create({
      data: { code: `HER${String(Date.now()).slice(-9)}`, type: AssetType.HERRAMIENTA, name: 'Rotomartillo QA', status: AssetStatus.MANTENIMIENTO, totalStock: 7 },
    });
    await prisma.stock.createMany({ data: [
      { assetId: asset.id, siteId: site.id, quantity: 2 },
      { assetId: asset.id, siteId: warehouse.id, quantity: 5 },
    ] });
    const movement = await prisma.movement.create({
      data: { kind: MovementKind.ALTA, assetId: asset.id, toSiteId: site.id, quantity: 2, userId: admin.id, idempotencyKey: `dashboard-${Date.now()}` },
    });
    await prisma.movementObservation.create({
      data: { movementId: movement.id, assetId: asset.id, type: ObservationType.DANADO, description: 'Revisar el cable de alimentación.' },
    });
  });
  afterAll(() => app.close());

  it('resume stock, obras, almacén y observaciones; indica cambios desde la sincronización', async () => {
    const dashboard = await api().get('/api/v1/dashboard').set(auth).expect(200);
    expect(dashboard.body.changedSince).toBe(true);
    expect(dashboard.body.totals.unitsOnSites).toBeGreaterThanOrEqual(2);
    expect(dashboard.body.totals.assetsInMaintenance).toBeGreaterThanOrEqual(1);
    expect(dashboard.body.totals.activeSites).toBeGreaterThanOrEqual(1);
    expect(dashboard.body.totals.warehouseUnits).toBeGreaterThanOrEqual(5);
    expect(dashboard.body.totals.openObservations).toBeGreaterThanOrEqual(1);
    expect(dashboard.body.sites.some((site: { name: string; summary: { units: number } }) =>
      site.name === 'Obra dashboard QA' && site.summary.units === 2,
    )).toBe(true);
    const old = await api().get('/api/v1/dashboard').query({ since: '2000-01-01T00:00:00.000Z' }).set(auth).expect(200);
    expect(old.body.changedSince).toBe(true);
    const future = await api().get('/api/v1/dashboard').query({ since: '2999-01-01T00:00:00.000Z' }).set(auth).expect(200);
    expect(future.body.changedSince).toBe(false);
  });

  it('filtra registros de auditoría y reserva la lectura para ADMIN', async () => {
    const site = await api().post('/api/v1/sites').set(auth).send({ name: 'Obra auditoría QA', ownerName: 'Equipo QA' }).expect(201);
    const logs = await api().get('/api/v1/audit-logs').query({ action: 'SITE_CREATED', entityType: 'site' }).set(auth).expect(200);
    expect(logs.body.data.some((row: { entityId: string; user: { id: string } }) => row.entityId === site.body.id && row.user.id === admin.id)).toBe(true);
    const operator = await seedUser(app, { role: Role.OPERADOR });
    const session = await loginOk(app, operator.dni, operator.password);
    await api().get('/api/v1/audit-logs').set({ Authorization: `Bearer ${session.accessToken}` }).expect(403);
  });
});
