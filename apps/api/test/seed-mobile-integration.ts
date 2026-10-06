import { execFileSync } from 'node:child_process';
import { PrismaClient, Role, SiteType } from '@prisma/client';
import { hash } from 'argon2';

async function main(): Promise<void> {
  if (process.env.NODE_ENV !== 'test') {
    throw new Error('La semilla móvil solo se permite con NODE_ENV=test.');
  }

  const dni = process.env.INTEGRATION_TEST_DNI;
  const password = process.env.INTEGRATION_TEST_PASSWORD;
  if (!dni || !/^[0-9]{8}$/.test(dni) || !password || password.length < 8) {
    throw new Error(
      'Define INTEGRATION_TEST_DNI (8 dígitos) e INTEGRATION_TEST_PASSWORD (8+ caracteres).',
    );
  }

  if (!process.env.DATABASE_URL) {
    throw new Error('Define DATABASE_URL para PostgreSQL local.');
  }
  const baseUrl = new URL(process.env.DATABASE_URL);
  if (!['localhost', '127.0.0.1', '::1'].includes(baseUrl.hostname)) {
    throw new Error('La semilla móvil requiere PostgreSQL en el equipo local.');
  }
  const testUrl = new URL(baseUrl);
  testUrl.pathname = '/a2c_test';
  const adminUrl = new URL(testUrl);
  adminUrl.pathname = '/postgres';

  const admin = new PrismaClient({ datasourceUrl: adminUrl.toString() });
  try {
    await admin.$executeRawUnsafe('CREATE DATABASE a2c_test');
  } catch (error) {
    if (!String(error).includes('already exists')) throw error;
  } finally {
    await admin.$disconnect();
  }

  execFileSync('pnpm', ['prisma', 'migrate', 'deploy'], {
    stdio: 'inherit',
    env: { ...process.env, DATABASE_URL: testUrl.toString() },
  });

  const prisma = new PrismaClient({ datasourceUrl: testUrl.toString() });
  try {
    const warehouse = await prisma.site.findFirst({
      where: { type: SiteType.ALMACEN },
      select: { id: true },
    });
    if (!warehouse) {
      await prisma.site.create({
        data: { type: SiteType.ALMACEN, name: 'Almacén central' },
      });
    }
    for (const prefix of ['MAQ', 'HER']) {
      await prisma.codeSequence.upsert({
        where: { prefix },
        update: {},
        create: { prefix },
      });
    }

    await prisma.user.upsert({
      where: { dni },
      update: {
        fullName: 'Administrador de integración',
        role: Role.ADMIN,
        active: true,
        mustChangePassword: false,
        passwordHash: await hash(password),
      },
      create: {
        dni,
        fullName: 'Administrador de integración',
        role: Role.ADMIN,
        active: true,
        mustChangePassword: false,
        passwordHash: await hash(password),
      },
    });
  } finally {
    await prisma.$disconnect();
  }

  console.log('Base a2c_test preparada con el administrador de integración.');
}

void main();
