import { execSync } from 'node:child_process';
import { PrismaClient } from '@prisma/client';
import { testDatabaseUrl } from './test-env';

/**
 * Prepara la base `a2c_test` (nunca la de desarrollo): la crea si falta, aplica
 * las migraciones y vacía las tablas. TRUNCATE no dispara el trigger de
 * inmutabilidad de `movements` (es por fila).
 */
export default async function setup(): Promise<void> {
  const testUrl = testDatabaseUrl();
  const adminUrl = new URL(testUrl);
  adminUrl.pathname = '/postgres';

  const admin = new PrismaClient({ datasourceUrl: adminUrl.toString() });
  try {
    await admin.$executeRawUnsafe('CREATE DATABASE a2c_test');
  } catch (e) {
    if (!String(e).includes('already exists')) throw e;
  } finally {
    await admin.$disconnect();
  }

  execSync('pnpm prisma migrate deploy', {
    stdio: 'ignore',
    env: { ...process.env, DATABASE_URL: testUrl },
  });

  const db = new PrismaClient({ datasourceUrl: testUrl });
  const tables = await db.$queryRaw<{ tablename: string }[]>`
    SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename <> '_prisma_migrations'`;
  if (tables.length) {
    await db.$executeRawUnsafe(
      `TRUNCATE ${tables.map((t) => `"${t.tablename}"`).join(', ')} RESTART IDENTITY CASCADE`,
    );
  }
  await db.$disconnect();
}
