import { INestApplication } from '@nestjs/common';
import { Role } from '@prisma/client';
import request from 'supertest';
import { PrismaService } from '../src/prisma/prisma.service';
import { createTestApp, login, loginOk, nextDni, seedUser } from './helpers';

describe('Autenticación (e2e) — RF-AUT', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  const api = () => request(app.getHttpServer());

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
  });
  afterAll(() => app.close());

  it('ingresa con DNI y contraseña y devuelve tokens y usuario', async () => {
    const u = await seedUser(app, { role: Role.ADMIN });
    const res = await login(app, u.dni, u.password).expect(200);
    expect(res.body.accessToken).toMatch(/^eyJ/);
    expect(res.body.refreshToken).toMatch(/^rt_/);
    expect(res.body.user).toMatchObject({ dni: u.dni, role: 'ADMIN', mustChangePassword: false });
    expect(res.body.user.passwordHash).toBeUndefined();
  });

  it('responde igual con DNI inexistente y con contraseña incorrecta', async () => {
    const u = await seedUser(app);
    const wrong = await login(app, u.dni, 'otraClave99').expect(401);
    const unknown = await login(app, nextDni(), 'otraClave99').expect(401);
    expect(wrong.body.code).toBe('CREDENCIALES_INVALIDAS');
    expect(unknown.body.code).toBe('CREDENCIALES_INVALIDAS');
    expect(wrong.body.title).toBe(unknown.body.title);
  });

  it('valida el formato del DNI (8 dígitos)', async () => {
    const res = await login(app, '1234', 'x').expect(422);
    expect(res.body.code).toBe('VALIDACION');
  });

  it('bloquea la cuenta 15 minutos tras 5 intentos fallidos (RF-AUT-04)', async () => {
    const u = await seedUser(app);
    for (let i = 0; i < 5; i++) await login(app, u.dni, 'malaClave1').expect(401);
    const res = await login(app, u.dni, u.password).expect(423);
    expect(res.body.code).toBe('CUENTA_BLOQUEADA');
    expect(new Date(res.body.lockedUntil).getTime()).toBeGreaterThan(Date.now() + 14 * 60_000);
    const audit = await prisma.auditLog.findFirst({ where: { entityId: u.id, action: 'LOGIN_LOCKED' } });
    expect(audit).not.toBeNull();
  });

  it('un ingreso correcto reinicia el contador de intentos', async () => {
    const u = await seedUser(app);
    for (let i = 0; i < 4; i++) await login(app, u.dni, 'malaClave1').expect(401);
    await login(app, u.dni, u.password).expect(200);
    for (let i = 0; i < 4; i++) await login(app, u.dni, 'malaClave1').expect(401);
    await login(app, u.dni, u.password).expect(200);
  });

  it('rechaza a un usuario desactivado (RN-13)', async () => {
    const u = await seedUser(app, { active: false });
    const res = await login(app, u.dni, u.password).expect(403);
    expect(res.body.code).toBe('CUENTA_DESACTIVADA');
  });

  it('exige access token en rutas protegidas', async () => {
    await api().get('/api/v1/auth/me').expect(401);
    await api().get('/api/v1/auth/me').set('Authorization', 'Bearer token-falso').expect(401);
  });

  it('con contraseña temporal solo permite /me y cambiar la contraseña (RF-AUT-05)', async () => {
    const u = await seedUser(app, { role: Role.ADMIN, mustChangePassword: true });
    const s = await loginOk(app, u.dni, u.password);
    const auth = { Authorization: `Bearer ${s.accessToken}` };

    await api().get('/api/v1/auth/me').set(auth).expect(200);
    const blocked = await api().get('/api/v1/users').set(auth).expect(403);
    expect(blocked.body.code).toBe('CAMBIO_CLAVE_REQUERIDO');

    const weak = await api()
      .post('/api/v1/auth/change-password')
      .set(auth)
      .send({ currentPassword: u.password, newPassword: `${u.dni}a` })
      .expect(422);
    expect(weak.body.code).toBe('VALIDACION');

    const changed = await api()
      .post('/api/v1/auth/change-password')
      .set(auth)
      .send({ currentPassword: u.password, newPassword: 'NuevaClave2026' })
      .expect(200);
    await api().get('/api/v1/users').set({ Authorization: `Bearer ${changed.body.accessToken}` }).expect(200);
    await login(app, u.dni, 'NuevaClave2026').expect(200);
    // El refresh anterior quedó revocado
    await api().post('/api/v1/auth/refresh').send({ refreshToken: s.refreshToken }).expect(401);
  });

  it('rota el refresh token y detecta su reutilización (docs/07 §3)', async () => {
    const u = await seedUser(app);
    const s = await loginOk(app, u.dni, u.password);

    const r1 = await api().post('/api/v1/auth/refresh').send({ refreshToken: s.refreshToken }).expect(200);
    expect(r1.body.refreshToken).not.toBe(s.refreshToken);

    // Reutilizar el token viejo revoca toda la sesión, incluido el nuevo.
    await api().post('/api/v1/auth/refresh').send({ refreshToken: s.refreshToken }).expect(401);
    await api().post('/api/v1/auth/refresh').send({ refreshToken: r1.body.refreshToken }).expect(401);
  });

  it('cerrar sesión revoca el refresh token', async () => {
    const u = await seedUser(app);
    const s = await loginOk(app, u.dni, u.password);
    await api().post('/api/v1/auth/logout').send({ refreshToken: s.refreshToken }).expect(204);
    await api().post('/api/v1/auth/refresh').send({ refreshToken: s.refreshToken }).expect(401);
  });
});
