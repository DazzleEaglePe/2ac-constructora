import type { AddressInfo } from 'node:net';
import { INestApplication } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Role } from '@prisma/client';
import Redis from 'ioredis';
import { io, Socket } from 'socket.io-client';
import request from 'supertest';
import type { Env } from '../src/config/env.schema';
import { REDIS } from '../src/redis/redis.module';
import { RedisIoAdapter } from '../src/realtime/redis-io.adapter';
import { createTestApp, loginOk, seedUser } from './helpers';

const once = <T>(socket: Socket, event: string) =>
  new Promise<T>((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`Timeout waiting for ${event}`)), 4000);
    socket.once(event, (value: T) => {
      clearTimeout(timer);
      resolve(value);
    });
  });

const matching = <T>(socket: Socket, event: string, predicate: (value: T) => boolean) =>
  new Promise<T>((resolve, reject) => {
    const timer = setTimeout(() => {
      socket.off(event, receive);
      reject(new Error(`Timeout waiting for matching ${event}`));
    }, 4000);
    const receive = (value: T) => {
      if (!predicate(value)) return;
      clearTimeout(timer);
      socket.off(event, receive);
      resolve(value);
    };
    socket.on(event, receive);
  });

describe('Tiempo real — RF-PAN', () => {
  let app: INestApplication;
  let secondApp: INestApplication;
  let socket: Socket;
  let secondSocket: Socket;
  let apiBase: string;
  let secondApiBase: string;
  let authorization: string;

  beforeAll(async () => {
    const configureSockets = async (testApp: INestApplication) => {
      const config = testApp.get(ConfigService<Env, true>);
      const adapter = await RedisIoAdapter.create(
        testApp,
        testApp.get<Redis>(REDIS),
        config.get('CORS_ORIGINS', { infer: true }),
      );
      testApp.useWebSocketAdapter(adapter);
    };
    app = await createTestApp(configureSockets);
    secondApp = await createTestApp(configureSockets);
    await app.listen(0, '127.0.0.1');
    await secondApp.listen(0, '127.0.0.1');
    const address = app.getHttpServer().address() as AddressInfo;
    const secondAddress = secondApp.getHttpServer().address() as AddressInfo;
    apiBase = `http://127.0.0.1:${address.port}`;
    secondApiBase = `http://127.0.0.1:${secondAddress.port}`;
    const admin = await seedUser(app, { role: Role.ADMIN });
    const session = await loginOk(app, admin.dni, admin.password);
    authorization = `Bearer ${session.accessToken}`;
    socket = io(`${apiBase}/realtime`, {
      transports: ['websocket'],
      auth: { token: session.accessToken },
      autoConnect: false,
      reconnection: false,
    });
    const ready = once<{ connectedAt: string }>(socket, 'realtime.ready');
    socket.connect();
    await ready;
    secondSocket = io(`${secondApiBase}/realtime`, {
      transports: ['websocket'],
      auth: { token: session.accessToken },
      autoConnect: false,
      reconnection: false,
    });
    const secondReady = once<{ connectedAt: string }>(secondSocket, 'realtime.ready');
    secondSocket.connect();
    await secondReady;
  });

  afterAll(async () => {
    socket?.disconnect();
    secondSocket?.disconnect();
    await app?.close();
    await secondApp?.close();
  });

  it('rechaza el handshake sin JWT válido', async () => {
    const unauthenticated = io(`${apiBase}/realtime`, {
      transports: ['websocket'],
      auth: { token: 'invalid-token' },
      autoConnect: false,
      reconnection: false,
    });
    const error = once<Error>(unauthenticated, 'connect_error');
    unauthenticated.connect();
    await expect(error).resolves.toBeInstanceOf(Error);
    unauthenticated.disconnect();
  });

  it('propaga cambios de obra a otra instancia después del commit en menos de 2 s', async () => {
    const update = once<{ id: string; updatedAt: string }>(socket, 'site.updated');
    const remoteUpdate = once<{ id: string; updatedAt: string }>(secondSocket, 'site.updated');
    const startedAt = Date.now();
    const response = await request(app.getHttpServer())
      .post('/api/v1/sites')
      .set('Authorization', authorization)
      .send({ name: 'Obra tiempo real QA', ownerName: 'Equipo QA' })
      .expect(201);
    await expect(update).resolves.toEqual(expect.objectContaining({ id: response.body.id }));
    await expect(remoteUpdate).resolves.toEqual(expect.objectContaining({ id: response.body.id }));
    expect(Date.now() - startedAt).toBeLessThan(2000);
  });

  it('notifica en otra instancia cuando un administrador revoca una sesión', async () => {
    const operator = await seedUser(app, { role: Role.OPERADOR });
    const session = await loginOk(app, operator.dni, operator.password);
    const operatorSocket = io(`${secondApiBase}/realtime`, {
      transports: ['websocket'],
      auth: { token: session.accessToken },
      autoConnect: false,
      reconnection: false,
    });
    const ready = once<{ connectedAt: string }>(operatorSocket, 'realtime.ready');
    operatorSocket.connect();
    await ready;

    const revoked = once<{ sessionId?: string }>(operatorSocket, 'session.revoked');
    await request(app.getHttpServer())
      .post(`/api/v1/users/${session.user.id}/deactivate`)
      .set('Authorization', authorization)
      .expect(200);
    await expect(revoked).resolves.toEqual({});
    operatorSocket.disconnect();
  });

  it('difunde los eventos de movimiento y stock con sus ubicaciones', async () => {
    const warehouse = await request(app.getHttpServer())
      .post('/api/v1/sites')
      .set('Authorization', authorization)
      .send({ name: 'Obra de origen realtime', ownerName: 'Equipo QA' })
      .expect(201);
    const site = await request(app.getHttpServer())
      .post('/api/v1/sites')
      .set('Authorization', authorization)
      .send({ name: 'Obra movimiento realtime', ownerName: 'Equipo QA' })
      .expect(201);
    const asset = await request(app.getHttpServer())
      .post('/api/v1/assets')
      .set('Authorization', authorization)
      .set('Idempotency-Key', `realtime-asset-${Date.now()}`)
      .send({
        type: 'HERRAMIENTA',
        name: 'Taladro realtime QA',
        initialQuantity: 2,
        initialSiteId: warehouse.body.id,
      })
      .expect(201);

    const movementEvent = once<{ assetId: string; fromSiteId: string; toSiteId: string }>(
      secondSocket,
      'movement.created',
    );
    const stockEvent = matching<{ assetId: string; siteIds: string[] }>(
      secondSocket,
      'stock.updated',
      (event) =>
        event.assetId === asset.body.id &&
        event.siteIds.includes(site.body.id) &&
        event.siteIds.includes(warehouse.body.id),
    );
    const startedAt = Date.now();
    await request(app.getHttpServer())
      .post('/api/v1/movements')
      .set('Authorization', authorization)
      .set('Idempotency-Key', `realtime-transfer-${Date.now()}`)
      .send({
        assetId: asset.body.id,
        fromSiteId: warehouse.body.id,
        toSiteId: site.body.id,
        quantity: 1,
      })
      .expect(201);
    await expect(movementEvent).resolves.toEqual(
      expect.objectContaining({
        assetId: asset.body.id,
        fromSiteId: warehouse.body.id,
        toSiteId: site.body.id,
      }),
    );
    await expect(stockEvent).resolves.toEqual({
      assetId: asset.body.id,
      siteIds: [warehouse.body.id, site.body.id],
    });
    expect(Date.now() - startedAt).toBeLessThan(2000);
  });
});
