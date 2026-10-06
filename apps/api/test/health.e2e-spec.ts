import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createTestApp } from './helpers';

// Requiere PostgreSQL y Redis (pnpm docker:up o servicios de CI).
describe('Health (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    app = await createTestApp();
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /health/live responde 200', async () => {
    await request(app.getHttpServer()).get('/health/live').expect(200, { status: 'ok' });
  });

  it('GET /health/ready verifica base de datos y Redis', async () => {
    const res = await request(app.getHttpServer()).get('/health/ready').expect(200);
    expect(res.body.info.database.status).toBe('up');
    expect(res.body.info.redis.status).toBe('up');
  });

  it('devuelve X-Request-Id y errores en formato problem+json', async () => {
    const res = await request(app.getHttpServer()).get('/api/v1/no-existe').expect(404);
    expect(res.headers['x-request-id']).toBeTruthy();
    expect(res.headers['content-type']).toContain('application/problem+json');
    expect(res.body.code).toBe('NO_ENCONTRADO');
  });
});
