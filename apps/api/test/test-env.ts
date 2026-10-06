import { readFileSync } from 'node:fs';
import { join } from 'node:path';

/** URL de la base de datos de pruebas: la misma del entorno, con la base `a2c_test`. */
export function testDatabaseUrl(): string {
  let base = process.env.DATABASE_URL;
  if (!base) {
    const env = readFileSync(join(__dirname, '..', '.env'), 'utf8');
    base = env.match(/^DATABASE_URL=(.+)$/m)?.[1]?.trim();
  }
  if (!base) throw new Error('DATABASE_URL no está definida (ni en el entorno ni en apps/api/.env)');
  const url = new URL(base);
  url.pathname = '/a2c_test';
  return url.toString();
}
