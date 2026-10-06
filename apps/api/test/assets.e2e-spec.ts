import { INestApplication } from '@nestjs/common';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { performance } from 'node:perf_hooks';
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
    warehouseId = (
      await prisma.site.create({
        data: { type: SiteType.ALMACEN, name: 'Almacén activos QA' },
      })
    ).id;
  });
  afterAll(() => app.close());

  it('crea herramienta con código secuencial, stock, movimiento ALTA y auditoría; reintento es idempotente', async () => {
    const preview = await api()
      .get('/api/v1/assets/next-code?type=HERRAMIENTA')
      .set(auth)
      .expect(200);
    expect(preview.body.code).toMatch(/^HER-\d{4,}$/);
    const key = `asset-create-${Date.now()}`;
    const payload = {
      type: 'HERRAMIENTA',
      name: '  Llave   francesa ',
      initialQuantity: 4,
      initialSiteId: warehouseId,
    };
    const created = await api()
      .post('/api/v1/assets')
      .set(auth)
      .set('Idempotency-Key', key)
      .send(payload)
      .expect(201);
    expect(created.body).toMatchObject({
      code: preview.body.code,
      name: 'Llave francesa',
      type: 'HERRAMIENTA',
      totalStock: 4,
      distribution: [{ siteId: warehouseId, quantity: 4 }],
    });
    const retry = await api()
      .post('/api/v1/assets')
      .set(auth)
      .set('Idempotency-Key', key)
      .send(payload)
      .expect(201);
    expect(retry.body.id).toBe(created.body.id);
    const movement = await prisma.movement.findUnique({
      where: { userId_idempotencyKey: { userId: admin.id, idempotencyKey: key } },
    });
    expect(movement).toMatchObject({ kind: 'ALTA', quantity: 4, toSiteId: warehouseId });
    expect(
      await prisma.auditLog.count({
        where: { entityId: created.body.id, action: 'ASSET_CREATED' },
      }),
    ).toBe(1);
  });

  it('impone una unidad por máquina y requiere Idempotency-Key', async () => {
    const invalid = await api()
      .post('/api/v1/assets')
      .set(auth)
      .set('Idempotency-Key', 'bad-machine')
      .send({ type: 'MAQUINA', name: 'Mezcladora', initialQuantity: 2, initialSiteId: warehouseId })
      .expect(422);
    expect(invalid.body.code).toBe('VALIDACION');
    await api()
      .post('/api/v1/assets')
      .set(auth)
      .send({ type: 'MAQUINA', name: 'Mezcladora', initialQuantity: 1, initialSiteId: warehouseId })
      .expect(400);
  });

  it('genera códigos distintos cuando dos altas ocurren simultáneamente', async () => {
    const makeAsset = (name: string) =>
      api()
        .post('/api/v1/assets')
        .set(auth)
        .set('Idempotency-Key', `parallel-${name}-${Date.now()}-${Math.random()}`)
        .send({
          type: 'HERRAMIENTA',
          name,
          initialQuantity: 1,
          initialSiteId: warehouseId,
        })
        .expect(201);

    const [first, second] = await Promise.all([
      makeAsset('Llave simultánea A'),
      makeAsset('Llave simultánea B'),
    ]);
    expect(first.body.code).toMatch(/^HER-\d{4,}$/);
    expect(second.body.code).toMatch(/^HER-\d{4,}$/);
    expect(first.body.code).not.toBe(second.body.code);
    expect(first.body.id).not.toBe(second.body.id);
  });

  it('busca por nombre/código y permite consultar distribución por ubicación', async () => {
    const found = await api().get('/api/v1/assets?q=llave').set(auth).expect(200);
    expect(found.body.some((asset: { name: string }) => asset.name === 'Llave francesa')).toBe(
      true,
    );
    const bySite = await api()
      .get(`/api/v1/assets?siteId=${warehouseId}&type=HERRAMIENTA`)
      .set(auth)
      .expect(200);
    expect(
      bySite.body.every((asset: { distribution: { siteId: string }[] }) =>
        asset.distribution.some((site) => site.siteId === warehouseId),
      ),
    ).toBe(true);
  });

  it('encuentra una pala y muestra cantidades por obra y almacén en los resultados', async () => {
    const site = await prisma.site.create({
      data: { type: SiteType.OBRA, name: 'Obra distribución pala QA' },
    });
    const asset = await prisma.asset.create({
      data: {
        code: `HER${Math.floor(Math.random() * 1_000_000_000)
          .toString()
          .padStart(9, '0')}`,
        type: AssetType.HERRAMIENTA,
        name: 'Pala de punta QA',
        totalStock: 5,
        stock: {
          create: [
            { siteId: warehouseId, quantity: 2 },
            { siteId: site.id, quantity: 3 },
          ],
        },
      },
    });

    const response = await api().get('/api/v1/assets/search?q=pala').set(auth).expect(200);
    const found = response.body.data.find((row: { id: string }) => row.id === asset.id);
    expect(found?.distribution).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          siteId: warehouseId,
          siteName: 'Almacén activos QA',
          quantity: 2,
        }),
        expect.objectContaining({ siteId: site.id, siteName: site.name, quantity: 3 }),
      ]),
    );
  });

  it('importa CSV por fila y devuelve los errores sin descartar las filas válidas', async () => {
    const key = `assets-import-${Date.now()}`;
    const csv = [
      'type,name,description,initialQuantity,siteName,status',
      'HERRAMIENTA,Pala importada,CSV QA,2,Almacén activos QA,OPERATIVO',
      'MAQUINA,Excavadora inválida,Debe ser una unidad,2,Almacén activos QA,OPERATIVO',
    ].join('\n');
    const upload = () =>
      api()
        .post('/api/v1/assets/import')
        .set(auth)
        .set('Idempotency-Key', key)
        .attach('file', Buffer.from(csv), 'activos.csv');

    const result = await upload().expect(201);
    expect(result.body).toMatchObject({ totalRows: 2, created: 1, failed: 1 });
    expect(result.body.rows[0]).toMatchObject({
      row: 2,
      status: 'CREATED',
      code: expect.stringMatching(/^HER-/),
    });
    expect(result.body.rows[1]).toMatchObject({ row: 3, status: 'ERROR' });
    expect(result.body.rows[1].errors.join(' ')).toContain('Una máquina');

    const retry = await upload().expect(201);
    expect(retry.body.rows[0].assetId).toBe(result.body.rows[0].assetId);
    expect(await prisma.asset.count({ where: { name: 'Pala importada' } })).toBe(1);
  });

  it('descarga la plantilla CSV solo para ADMIN', async () => {
    const template = await api().get('/api/v1/assets/import/template').set(auth).expect(200);
    expect(template.headers['content-type']).toContain('text/csv');
    expect(template.text).toContain('type,name,description,initialQuantity,siteName,status');
  });

  it('lee XLSX y devuelve errores por fila para datos inválidos', async () => {
    const result = await api()
      .post('/api/v1/assets/import')
      .set(auth)
      .set('Idempotency-Key', `assets-xlsx-${Date.now()}`)
      .attach('file', readFileSync(join(__dirname, 'fixtures/assets-import.xlsx')), 'activos.xlsx')
      .expect(201);
    expect(result.body).toMatchObject({ totalRows: 1, created: 0, failed: 1 });
    expect(result.body.rows[0]).toMatchObject({ row: 2, status: 'ERROR' });
    expect(result.body.rows[0].errors.join(' ')).toContain('initialSiteId');
  });

  const assetImportPerformanceTest = process.env.RUN_ASSET_IMPORT_PERF === '1' ? it : it.skip;
  assetImportPerformanceTest(
    'importa 500 activos desde Excel en menos de un minuto',
    async () => {
      const startedAt = performance.now();
      const result = await api()
        .post('/api/v1/assets/import')
        .set(auth)
        .set('Idempotency-Key', `import-500-${Date.now()}`)
        .attach(
          'file',
          readFileSync(join(__dirname, 'fixtures/assets-import-500.xlsx')),
          'activos-500.xlsx',
        )
        .expect(201);
      const elapsedMs = performance.now() - startedAt;

      expect(result.body).toMatchObject({ totalRows: 500, created: 500, failed: 0 });
      expect(elapsedMs).toBeLessThan(60_000);
    },
    90_000,
  );

  it('busca sin distinguir acentos y pagina resultados sin repetir activos', async () => {
    const tag = `qaasset${Date.now()}`;
    const created = [] as { id: string; code: string }[];
    for (const name of [
      `${tag} Amoladora Angular A`,
      `${tag} Amoladora Ángular B`,
      `${tag} Amoladora Angular C`,
    ]) {
      const response = await api()
        .post('/api/v1/assets')
        .set(auth)
        .set('Idempotency-Key', `search-${Date.now()}-${Math.random()}`)
        .send({ type: 'HERRAMIENTA', name, initialQuantity: 1, initialSiteId: warehouseId })
        .expect(201);
      created.push({ id: response.body.id, code: response.body.code });
    }

    const first = await api()
      .get('/api/v1/assets/search')
      .query({ q: `${tag} amoladora angular`, siteId: warehouseId, type: 'HERRAMIENTA', limit: 2 })
      .set(auth)
      .expect(200);
    expect(first.body.data).toHaveLength(2);
    expect(first.body.nextCursor).toBeTruthy();
    const second = await api()
      .get('/api/v1/assets/search')
      .query({
        q: `${tag} amoladora angular`,
        siteId: warehouseId,
        type: 'HERRAMIENTA',
        limit: 2,
        cursor: first.body.nextCursor,
      })
      .set(auth)
      .expect(200);
    expect(second.body.data).toHaveLength(1);
    expect(second.body.nextCursor).toBeNull();
    const foundIds = [...first.body.data, ...second.body.data].map(
      (asset: { id: string }) => asset.id,
    );
    expect(new Set(foundIds).size).toBe(3);
    expect(foundIds.sort()).toEqual(created.map((asset) => asset.id).sort());

    const byCode = await api()
      .get('/api/v1/assets/search')
      .query({ q: created[0].code })
      .set(auth)
      .expect(200);
    expect(byCode.body.data.map((asset: { id: string }) => asset.id)).toContain(created[0].id);
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
    const updated = await api()
      .patch(`/api/v1/assets/${created.id}`)
      .set(auth)
      .send({ name: 'Pinza universal', description: 'Aislada' })
      .expect(200);
    expect(updated.body).toMatchObject({ name: 'Pinza universal', description: 'Aislada' });
    const missingReason = await api()
      .post(`/api/v1/assets/${created.id}/status`)
      .set(auth)
      .send({ status: 'BAJA' })
      .expect(422);
    expect(missingReason.body.code).toBe('VALIDACION');
    const retired = await api()
      .post(`/api/v1/assets/${created.id}/status`)
      .set(auth)
      .send({ status: 'BAJA', reason: 'Daño irreparable' })
      .expect(200);
    expect(retired.body.status).toBe('BAJA');
    expect(
      await prisma.auditLog.count({
        where: { entityId: created.id, action: 'ASSET_STATUS_CHANGED' },
      }),
    ).toBe(1);
  });

  it('registra notas con autor y auditoría para el activo', async () => {
    const asset = await api()
      .post('/api/v1/assets')
      .set(auth)
      .set('Idempotency-Key', `asset-note-${Date.now()}`)
      .send({
        type: 'HERRAMIENTA',
        name: 'Nivel de mano',
        initialQuantity: 1,
        initialSiteId: warehouseId,
      })
      .expect(201);
    const note = await api()
      .post(`/api/v1/assets/${asset.body.id}/notes`)
      .set(auth)
      .send({ body: 'Revisar calibración al cierre de mes.' })
      .expect(201);
    expect(note.body).toMatchObject({
      body: 'Revisar calibración al cierre de mes.',
      userName: admin.fullName,
    });
    const notes = await api().get(`/api/v1/assets/${asset.body.id}/notes`).set(auth).expect(200);
    expect(notes.body).toHaveLength(1);
    expect(
      await prisma.auditLog.count({
        where: { entityId: asset.body.id, action: 'ASSET_NOTE_ADDED' },
      }),
    ).toBe(1);
  });

  it('solo ADMIN puede crear, importar y consultar códigos de activos', async () => {
    const operator = await seedUser(app, { role: Role.OPERADOR });
    const session = await loginOk(app, operator.dni, operator.password);
    const operatorAuth = { Authorization: `Bearer ${session.accessToken}` };
    await api().get('/api/v1/assets').set(operatorAuth).expect(200);
    await api().get('/api/v1/assets/next-code?type=MAQUINA').set(operatorAuth).expect(403);
    await api().get('/api/v1/assets/import/template').set(operatorAuth).expect(403);
    await api()
      .post('/api/v1/assets/import')
      .set(operatorAuth)
      .set('Idempotency-Key', 'operator-import')
      .attach('file', Buffer.from('type,name'), 'activos.csv')
      .expect(403);
    await api()
      .post('/api/v1/assets')
      .set(operatorAuth)
      .set('Idempotency-Key', 'operator-create')
      .send({
        type: 'HERRAMIENTA',
        name: 'Martillo',
        initialQuantity: 1,
        initialSiteId: warehouseId,
      })
      .expect(403);
  });
});
