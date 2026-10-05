import { INestApplication } from '@nestjs/common';
import { AssetType, Role, SiteType } from '@prisma/client';
import request from 'supertest';
import { PrismaService } from '../src/prisma/prisma.service';
import { createTestApp, loginOk, seedUser } from './helpers';

describe('Catálogo de activos — RF-ACT', () => {
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
    warehouseId = (await prisma.site.create({
      data: { type: SiteType.ALMACEN, name: 'Almacén activos QA' },
    })).id;
  });
  afterAll(() => app.close());

  it('crea herramienta con código secuencial, stock, movimiento ALTA y auditoría; reintento es idempotente', async () => {
    const preview = await api().get('/api/v1/assets/next-code?type=HERRAMIENTA').set(auth).expect(200);
    expect(preview.body.code).toMatch(/^HER-\d{4,}$/);
    const key = `asset-create-${Date.now()}`;
    const payload = {
      type: 'HERRAMIENTA', name: '  Llave   francesa ',
      initialQuantity: 4, initialSiteId: warehouseId,
    };
    const created = await api().post('/api/v1/assets').set(auth).set('Idempotency-Key', key).send(payload).expect(201);
    expect(created.body).toMatchObject({
      code: preview.body.code, name: 'Llave francesa', type: 'HERRAMIENTA',
      totalStock: 4, distribution: [{ siteId: warehouseId, quantity: 4 }],
    });
    const retry = await api().post('/api/v1/assets').set(auth).set('Idempotency-Key', key).send(payload).expect(201);
    expect(retry.body.id).toBe(created.body.id);
    const movement = await prisma.movement.findUnique({ where: { userId_idempotencyKey: { userId: admin.id, idempotencyKey: key } } });
    expect(movement).toMatchObject({ kind: 'ALTA', quantity: 4, toSiteId: warehouseId });
    expect(await prisma.auditLog.count({ where: { entityId: created.body.id, action: 'ASSET_CREATED' } })).toBe(1);
  });

  it('impone una unidad por máquina y requiere Idempotency-Key', async () => {
    const invalid = await api().post('/api/v1/assets').set(auth).set('Idempotency-Key', 'bad-machine')
      .send({ type: 'MAQUINA', name: 'Mezcladora', initialQuantity: 2, initialSiteId: warehouseId }).expect(422);
    expect(invalid.body.code).toBe('VALIDACION');
    await api().post('/api/v1/assets').set(auth)
      .send({ type: 'MAQUINA', name: 'Mezcladora', initialQuantity: 1, initialSiteId: warehouseId }).expect(400);
  });

  it('busca por nombre/código y permite consultar distribución por ubicación', async () => {
    const found = await api().get('/api/v1/assets?q=llave').set(auth).expect(200);
    expect(found.body.some((asset: { name: string }) => asset.name === 'Llave francesa')).toBe(true);
    const bySite = await api().get(`/api/v1/assets?siteId=${warehouseId}&type=HERRAMIENTA`).set(auth).expect(200);
    expect(bySite.body.every((asset: { distribution: { siteId: string }[] }) => asset.distribution.some((site) => site.siteId === warehouseId))).toBe(true);
  });

  it('edita el activo y exige un motivo para darlo de baja', async () => {
    const created = await prisma.asset.create({
      data: {
        code: `HER${String(Date.now()).slice(-9)}`,
        type: AssetType.HERRAMIENTA,
        name: 'Pinza QA',
        totalStock: 1,
      },
    });
    const updated = await api().patch(`/api/v1/assets/${created.id}`).set(auth)
      .send({ name: 'Pinza universal', description: 'Aislada' }).expect(200);
    expect(updated.body).toMatchObject({ name: 'Pinza universal', description: 'Aislada' });
    const missingReason = await api().post(`/api/v1/assets/${created.id}/status`).set(auth)
      .send({ status: 'BAJA' }).expect(422);
    expect(missingReason.body.code).toBe('VALIDACION');
    const retired = await api().post(`/api/v1/assets/${created.id}/status`).set(auth)
      .send({ status: 'BAJA', reason: 'Daño irreparable' }).expect(200);
    expect(retired.body.status).toBe('BAJA');
    expect(await prisma.auditLog.count({ where: { entityId: created.id, action: 'ASSET_STATUS_CHANGED' } })).toBe(1);
  });

  it('registra notas con autor y auditoría para el activo', async () => {
    const asset = await api().post('/api/v1/assets').set(auth).set('Idempotency-Key', `asset-note-${Date.now()}`)
      .send({ type: 'HERRAMIENTA', name: 'Nivel de mano', initialQuantity: 1, initialSiteId: warehouseId }).expect(201);
    const note = await api().post(`/api/v1/assets/${asset.body.id}/notes`).set(auth)
      .send({ body: 'Revisar calibración al cierre de mes.' }).expect(201);
    expect(note.body).toMatchObject({ body: 'Revisar calibración al cierre de mes.', userName: admin.fullName });
    const notes = await api().get(`/api/v1/assets/${asset.body.id}/notes`).set(auth).expect(200);
    expect(notes.body).toHaveLength(1);
    expect(await prisma.auditLog.count({ where: { entityId: asset.body.id, action: 'ASSET_NOTE_ADDED' } })).toBe(1);
  });

  it('solo ADMIN puede crear activos y ver el siguiente código', async () => {
    const operator = await seedUser(app, { role: Role.OPERADOR });
    const session = await loginOk(app, operator.dni, operator.password);
    const operatorAuth = { Authorization: `Bearer ${session.accessToken}` };
    await api().get('/api/v1/assets').set(operatorAuth).expect(200);
    await api().get('/api/v1/assets/next-code?type=MAQUINA').set(operatorAuth).expect(403);
    await api().post('/api/v1/assets').set(operatorAuth).set('Idempotency-Key', 'operator-create')
      .send({ type: 'HERRAMIENTA', name: 'Martillo', initialQuantity: 1, initialSiteId: warehouseId }).expect(403);
  });
});
