import { INestApplication } from '@nestjs/common';
import { AssetType, Role, SiteStatus, SiteType } from '@prisma/client';
import request from 'supertest';
import { PrismaService } from '../src/prisma/prisma.service';
import { createTestApp, loginOk, seedUser } from './helpers';

describe('Movimientos — RF-MOV', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let admin: Awaited<ReturnType<typeof seedUser>>;
  let auth: { Authorization: string };
  let warehouseId: string;
  let siteId: string;
  const api = () => request(app.getHttpServer());

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    admin = await seedUser(app, { role: Role.ADMIN });
    const session = await loginOk(app, admin.dni, admin.password);
    auth = { Authorization: `Bearer ${session.accessToken}` };
    warehouseId = (await prisma.site.create({ data: { type: SiteType.ALMACEN, name: 'Almacén movimientos QA' } })).id;
    siteId = (await prisma.site.create({ data: { type: SiteType.OBRA, name: 'Obra movimientos QA', ownerName: 'Equipo QA' } })).id;
  });
  afterAll(() => app.close());

  async function createAsset(name: string, quantity: number, type: AssetType = AssetType.HERRAMIENTA) {
    const response = await api().post('/api/v1/assets').set(auth)
      .set('Idempotency-Key', `move-fixture-${Date.now()}-${Math.random()}`)
      .send({ type, name, initialQuantity: quantity, initialSiteId: warehouseId }).expect(201);
    return response.body as { id: string; totalStock: number };
  }

  it('traslada stock, registra observación, actualiza historial e idempotencia', async () => {
    const asset = await createAsset('Taladro de impacto', 3);
    const key = `move-${Date.now()}`;
    const payload = {
      assetId: asset.id, fromSiteId: warehouseId, toSiteId: siteId,
      quantity: 2, note: 'Sale con batería cargada',
      observation: { type: 'DANADO', description: 'La carcasa tiene una fisura.' },
    };
    const moved = await api().post('/api/v1/movements').set(auth).set('Idempotency-Key', key).send(payload).expect(201);
    expect(moved.body).toMatchObject({
      kind: 'TRASLADO', quantity: 2, note: payload.note,
      fromSite: { id: warehouseId }, toSite: { id: siteId },
      stockAfter: { from: 1, to: 2 },
      observation: { type: 'DANADO', description: 'La carcasa tiene una fisura.', status: 'ABIERTA' },
      user: { id: admin.id },
    });
    const retry = await api().post('/api/v1/movements').set(auth).set('Idempotency-Key', key).send(payload).expect(201);
    expect(retry.body.id).toBe(moved.body.id);
    expect(retry.body.stockAfter).toEqual(moved.body.stockAfter);
    const stocks = await prisma.stock.findMany({ where: { assetId: asset.id } });
    expect(stocks.reduce((total, row) => total + row.quantity, 0)).toBe(asset.totalStock);
    expect((await api().get(`/api/v1/movements?assetId=${asset.id}`).set(auth).expect(200)).body).toHaveLength(2);
    const observations = await api().get(`/api/v1/observations?status=ABIERTA&assetId=${asset.id}`).set(auth).expect(200);
    expect(observations.body).toHaveLength(1);
    const resolved = await api().post(`/api/v1/observations/${observations.body[0].id}/resolve`).set(auth)
      .send({ resolution: 'Se cambió la carcasa y quedó revisada.' }).expect(200);
    expect(resolved.body).toMatchObject({ status: 'ATENDIDA', resolution: 'Se cambió la carcasa y quedó revisada.', resolvedById: admin.id });
  });

  it('rechaza origen igual a destino, falta de stock, máquina dividida y destino cerrado', async () => {
    const tool = await createAsset('Llave de impacto', 1);
    const same = await api().post('/api/v1/movements').set(auth).set('Idempotency-Key', 'same-site')
      .send({ assetId: tool.id, fromSiteId: warehouseId, toSiteId: warehouseId, quantity: 1 }).expect(422);
    expect(same.body.code).toBe('ORIGEN_IGUAL_DESTINO');
    const insufficient = await api().post('/api/v1/movements').set(auth).set('Idempotency-Key', 'insufficient-stock')
      .send({ assetId: tool.id, fromSiteId: warehouseId, toSiteId: siteId, quantity: 2 }).expect(409);
    expect(insufficient.body.code).toBe('STOCK_INSUFICIENTE');
    const machine = await createAsset('Mezcladora QA', 1, AssetType.MAQUINA);
    const split = await api().post('/api/v1/movements').set(auth).set('Idempotency-Key', 'machine-split')
      .send({ assetId: machine.id, fromSiteId: warehouseId, toSiteId: siteId, quantity: 2 }).expect(422);
    expect(split.body.code).toBe('MAQUINA_UNIDAD_UNICA');
    await prisma.site.update({ where: { id: siteId }, data: { status: SiteStatus.CERRADA } });
    const closed = await api().post('/api/v1/movements').set(auth).set('Idempotency-Key', 'closed-target')
      .send({ assetId: tool.id, fromSiteId: warehouseId, toSiteId: siteId, quantity: 1 }).expect(409);
    expect(closed.body.code).toBe('OBRA_CERRADA');
    await prisma.site.update({ where: { id: siteId }, data: { status: SiteStatus.ACTIVA } });
  });

  it('serializa dos traslados concurrentes y nunca deja stock negativo', async () => {
    const asset = await createAsset('Set de brocas', 2);
    const send = (key: string) => api().post('/api/v1/movements').set(auth).set('Idempotency-Key', key)
      .send({ assetId: asset.id, fromSiteId: warehouseId, toSiteId: siteId, quantity: 2 });
    const responses = await Promise.all([send(`parallel-a-${Date.now()}`), send(`parallel-b-${Date.now()}`)]);
    expect(responses.map((response) => response.status).sort()).toEqual([201, 409]);
    const stocks = await prisma.stock.findMany({ where: { assetId: asset.id } });
    expect(stocks.every((row) => row.quantity >= 0)).toBe(true);
    expect(stocks.reduce((total, row) => total + row.quantity, 0)).toBe(asset.totalStock);
  });

  it('permite el traslado a operadores autenticados', async () => {
    const operator = await seedUser(app, { role: Role.OPERADOR });
    const session = await loginOk(app, operator.dni, operator.password);
    const tool = await createAsset('Esmeril manual', 1);
    await api().post('/api/v1/movements').set({ Authorization: `Bearer ${session.accessToken}` })
      .set('Idempotency-Key', `operator-move-${Date.now()}`)
      .send({ assetId: tool.id, fromSiteId: warehouseId, toSiteId: siteId, quantity: 1 }).expect(201);
    await api().post('/api/v1/observations/00000000-0000-4000-8000-000000000000/resolve')
      .set({ Authorization: `Bearer ${session.accessToken}` }).send({ resolution: 'No autorizado' }).expect(403);
  });
});
