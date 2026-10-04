import { INestApplication } from '@nestjs/common';
import { Role } from '@prisma/client';
import request from 'supertest';
import { PrismaService } from '../src/prisma/prisma.service';
import { createTestApp, login, loginOk, nextDni, seedUser } from './helpers';

describe('Usuarios (e2e) — RF-USR', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let admin: Awaited<ReturnType<typeof seedUser>>;
  let auth: { Authorization: string };
  const api = () => request(app.getHttpServer());

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    admin = await seedUser(app, { role: Role.ADMIN });
    const s = await loginOk(app, admin.dni, admin.password);
    auth = { Authorization: `Bearer ${s.accessToken}` };
  });
  afterAll(() => app.close());

  it('el operador no puede gestionar usuarios (docs/07 §4)', async () => {
    const op = await seedUser(app, { role: Role.OPERADOR });
    const s = await loginOk(app, op.dni, op.password);
    const res = await api().get('/api/v1/users').set({ Authorization: `Bearer ${s.accessToken}` }).expect(403);
    expect(res.body.code).toBe('SIN_PERMISO');
  });

  it('crea un operador con contraseña temporal y queda auditado (RF-USR-02)', async () => {
    const dni = nextDni();
    const res = await api()
      .post('/api/v1/users')
      .set(auth)
      .send({ dni, fullName: '  Martín   Ruiz ', role: 'OPERADOR', temporaryPassword: 'Temporal2026' })
      .expect(201);
    expect(res.body).toMatchObject({ dni, fullName: 'Martín Ruiz', role: 'OPERADOR', mustChangePassword: true });

    const s = await loginOk(app, dni, 'Temporal2026');
    expect(s.user).toMatchObject({ mustChangePassword: true });
    const audit = await prisma.auditLog.findFirst({ where: { entityId: res.body.id, action: 'USER_CREATED' } });
    expect(audit?.userId).toBe(admin.id);
  });

  it('rechaza DNI duplicado, DNI inválido y contraseña débil', async () => {
    const dup = await api()
      .post('/api/v1/users')
      .set(auth)
      .send({ dni: admin.dni, fullName: 'Otra Persona', role: 'OPERADOR', temporaryPassword: 'Temporal2026' })
      .expect(409);
    expect(dup.body.code).toBe('DNI_DUPLICADO');

    const badDni = await api()
      .post('/api/v1/users')
      .set(auth)
      .send({ dni: '123456789', fullName: 'Otra Persona', role: 'OPERADOR', temporaryPassword: 'Temporal2026' })
      .expect(422);
    expect(badDni.body.code).toBe('VALIDACION');

    const weak = await api()
      .post('/api/v1/users')
      .set(auth)
      .send({ dni: nextDni(), fullName: 'Otra Persona', role: 'OPERADOR', temporaryPassword: 'solotexto' })
      .expect(422);
    expect(weak.body.code).toBe('VALIDACION');
  });

  it('lista y busca usuarios por nombre o DNI (RF-USR-01)', async () => {
    const u = await seedUser(app);
    const byDni = await api().get(`/api/v1/users?q=${u.dni}`).set(auth).expect(200);
    expect(byDni.body.data.map((x: { id: string }) => x.id)).toContain(u.id);
    const ops = await api().get('/api/v1/users?role=OPERADOR&limit=2').set(auth).expect(200);
    expect(ops.body.data.length).toBeLessThanOrEqual(2);
    expect(ops.body.data.every((x: { role: string }) => x.role === 'OPERADOR')).toBe(true);
  });

  it('edita nombre y rol (RF-USR-03)', async () => {
    const u = await seedUser(app);
    const res = await api()
      .patch(`/api/v1/users/${u.id}`)
      .set(auth)
      .send({ fullName: 'Lucía Gómez', role: 'ADMIN' })
      .expect(200);
    expect(res.body).toMatchObject({ fullName: 'Lucía Gómez', role: 'ADMIN' });
  });

  it('desactivar cierra sus sesiones; reactivar devuelve el acceso (RF-USR-04)', async () => {
    const u = await seedUser(app);
    const s = await loginOk(app, u.dni, u.password);

    await api().post(`/api/v1/users/${u.id}/deactivate`).set(auth).expect(200);
    await api().post('/api/v1/auth/refresh').send({ refreshToken: s.refreshToken }).expect(401);
    expect((await login(app, u.dni, u.password)).body.code).toBe('CUENTA_DESACTIVADA');

    await api().post(`/api/v1/users/${u.id}/activate`).set(auth).expect(200);
    await login(app, u.dni, u.password).expect(200);
  });

  it('el administrador no puede desactivarse a sí mismo', async () => {
    const res = await api().post(`/api/v1/users/${admin.id}/deactivate`).set(auth).expect(409);
    expect(res.body.code).toBe('NO_PUEDES_DESACTIVARTE');
  });

  it('siempre queda al menos un administrador activo', async () => {
    // Desactiva a todos los demás administradores para dejar a `admin` como el único.
    await prisma.user.updateMany({
      where: { role: Role.ADMIN, id: { not: admin.id } },
      data: { active: false },
    });
    const res = await api().patch(`/api/v1/users/${admin.id}`).set(auth).send({ role: 'OPERADOR' }).expect(409);
    expect(res.body.code).toBe('ULTIMO_ADMINISTRADOR');
  });

  it('restablece la contraseña con una temporal de un solo uso (RF-USR-05)', async () => {
    const u = await seedUser(app);
    const res = await api().post(`/api/v1/users/${u.id}/reset-password`).set(auth).expect(200);
    const temp: string = res.body.temporaryPassword;
    expect(temp).toMatch(/^(?=.*[A-Za-z])(?=.*[0-9]).{10}$/);

    await login(app, u.dni, u.password).expect(401);
    const s = await loginOk(app, u.dni, temp);
    expect(s.user).toMatchObject({ mustChangePassword: true });
  });

  it('responde 404 para un usuario inexistente', async () => {
    const res = await api().get('/api/v1/users/7c1e1c1e-0000-4000-8000-000000000000').set(auth).expect(404);
    expect(res.body.code).toBe('NO_ENCONTRADO');
  });
});
