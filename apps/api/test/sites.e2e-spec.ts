import { INestApplication } from '@nestjs/common';
import { AssetStatus, AssetType, MovementKind, Role, SiteStatus, SiteType } from '@prisma/client';
import request from 'supertest';
import { PrismaService } from '../src/prisma/prisma.service';
import { createTestApp, loginOk, seedUser } from './helpers';

describe('Obras y almacén (e2e) — RF-UBI', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let admin: Awaited<ReturnType<typeof seedUser>>;
  let auth: { Authorization: string };
  let warehouseId: string;
  const api = () => request(app.getHttpServer());

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    admin = await seedUser(app, { role: Role.ADMIN });
    const session = await loginOk(app, admin.dni, admin.password);
    auth = { Authorization: `Bearer ${session.accessToken}` };
    const warehouse = await prisma.site.create({
      data: { type: SiteType.ALMACEN, name: 'Almacén central' },
    });
    warehouseId = warehouse.id;
  });

  afterAll(() => app.close());

  it('crea y busca una obra; guarda coordenadas y deja rastro de auditoría', async () => {
    const created = await api()
      .post('/api/v1/sites')
      .set(auth)
      .send({
        name: '  Obra   Juan Ramírez ',
        ownerName: ' Juan   Ramírez ',
        address: 'Calle Los Pinos 245, Lima',
        lat: -12.0464,
        lng: -77.0428,
      })
      .expect(201);

    expect(created.body).toMatchObject({
      type: 'OBRA',
      name: 'Obra Juan Ramírez',
      ownerName: 'Juan Ramírez',
      address: 'Calle Los Pinos 245, Lima',
      lat: -12.0464,
      lng: -77.0428,
      status: 'ACTIVA',
      summary: { units: 0, assetCount: 0, lastMovementAt: null, topItems: [] },
    });

    const byOwner = await api().get('/api/v1/sites?q=juan').set(auth).expect(200);
    expect(byOwner.body.map((site: { id: string }) => site.id)).toContain(created.body.id);
    const audit = await prisma.auditLog.findFirst({
      where: { entityId: created.body.id, action: 'SITE_CREATED' },
    });
    expect(audit?.userId).toBe(admin.id);
  });

  it('suma stock por obra y almacén, entrega filtros y respeta auditoría de cierres', async () => {
    const site = await prisma.site.create({
      data: {
        type: SiteType.OBRA,
        name: 'Obra QA Stock',
        ownerName: 'Equipo QA',
        address: 'Lima',
      },
    });
    const asset = await prisma.asset.create({
      data: {
        code: `HER${String(Date.now()).slice(-9)}`,
        type: AssetType.HERRAMIENTA,
        name: 'Taladro',
        totalStock: 3,
        status: AssetStatus.OPERATIVO,
      },
    });
    await prisma.stock.createMany({
      data: [
        { assetId: asset.id, siteId: site.id, quantity: 2 },
        { assetId: asset.id, siteId: warehouseId, quantity: 1 },
      ],
    });
    const movement = await prisma.movement.create({
      data: {
        kind: MovementKind.ALTA,
        assetId: asset.id,
        toSiteId: site.id,
        quantity: 2,
        userId: admin.id,
        idempotencyKey: `site-${Date.now()}`,
      },
    });

    const detail = await api().get(`/api/v1/sites/${site.id}`).set(auth).expect(200);
    expect(detail.body.summary).toMatchObject({
      units: 2,
      assetCount: 1,
      lastMovementAt: movement.createdAt.toISOString(),
      topItems: [{ name: 'Taladro', quantity: 2 }],
    });
    const stock = await api().get(`/api/v1/sites/${site.id}/stock?type=HERRAMIENTA`).set(auth).expect(200);
    expect(stock.body).toMatchObject([{ id: asset.id, code: asset.code, quantity: 2 }]);

    const blocked = await api().post(`/api/v1/sites/${site.id}/close`).set(auth).expect(409);
    expect(blocked.body.code).toBe('OBRA_CERRADA');
    await prisma.stock.update({ where: { assetId_siteId: { assetId: asset.id, siteId: site.id } }, data: { quantity: 0 } });

    const closed = await api().post(`/api/v1/sites/${site.id}/close`).set(auth).expect(200);
    expect(closed.body.status).toBe(SiteStatus.CERRADA);
    const reopened = await api().post(`/api/v1/sites/${site.id}/reopen`).set(auth).expect(200);
    expect(reopened.body.status).toBe(SiteStatus.ACTIVA);
    const audits = await prisma.auditLog.findMany({
      where: { entityId: site.id, action: { in: ['SITE_CLOSED', 'SITE_REOPENED'] } },
    });
    expect(audits.map(({ action }) => action).sort()).toEqual(['SITE_CLOSED', 'SITE_REOPENED']);
  });

  it('permite consultar ubicaciones a operadores, pero reserva cambios a ADMIN', async () => {
    const operator = await seedUser(app, { role: Role.OPERADOR });
    const session = await loginOk(app, operator.dni, operator.password);
    const operatorAuth = { Authorization: `Bearer ${session.accessToken}` };

    await api().get('/api/v1/sites').set(operatorAuth).expect(200);
    const denied = await api()
      .post('/api/v1/sites')
      .set(operatorAuth)
      .send({ name: 'Obra sin permiso', ownerName: 'Operador QA' })
      .expect(403);
    expect(denied.body.code).toBe('SIN_PERMISO');
  });

  it('rechaza coordenadas incompletas y protege el almacén central del cierre', async () => {
    const incomplete = await api()
      .post('/api/v1/sites')
      .set(auth)
      .send({ name: 'Obra Coordenadas', ownerName: 'Equipo QA', lat: -12.04 })
      .expect(422);
    expect(incomplete.body.code).toBe('VALIDACION');

    const closed = await api().post(`/api/v1/sites/${warehouseId}/close`).set(auth).expect(409);
    expect(closed.body.code).toBe('OBRA_CERRADA');
  });
});
