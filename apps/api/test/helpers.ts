import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { Role } from '@prisma/client';
import { hash } from 'argon2';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';
import { setupApp } from '../src/setup-app';

export async function createTestApp(
  configure?: (app: INestApplication) => Promise<void> | void,
): Promise<INestApplication> {
  const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
  const app = moduleRef.createNestApplication({ bufferLogs: true });
  await configure?.(app);
  setupApp(app);
  await app.init();
  return app;
}

let dniSeq = 10_000_000 + Math.floor(Math.random() * 80_000_000);
/** DNI único de 8 dígitos para cada prueba. */
export const nextDni = (): string => String(dniSeq++);

/** Crea un usuario directamente en la base (sin pasar por la API). */
export async function seedUser(
  app: INestApplication,
  opts: { role?: Role; password?: string; mustChangePassword?: boolean; active?: boolean } = {},
) {
  const prisma = app.get(PrismaService);
  const password = opts.password ?? 'Clave2026a';
  const user = await prisma.user.create({
    data: {
      dni: nextDni(),
      fullName: 'Usuario de prueba',
      role: opts.role ?? Role.OPERADOR,
      passwordHash: await hash(password),
      mustChangePassword: opts.mustChangePassword ?? false,
      active: opts.active ?? true,
    },
  });
  return { ...user, password };
}

export function login(app: INestApplication, dni: string, password: string) {
  return request(app.getHttpServer()).post('/api/v1/auth/login').send({ dni, password });
}

export async function loginOk(app: INestApplication, dni: string, password: string) {
  const res = await login(app, dni, password);
  if (res.status !== 200) throw new Error(`login falló: ${res.status} ${JSON.stringify(res.body)}`);
  return res.body as { accessToken: string; refreshToken: string; user: { id: string } };
}
