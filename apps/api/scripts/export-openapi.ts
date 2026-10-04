import 'reflect-metadata';
import { writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { NestFactory } from '@nestjs/core';
import { stringify } from 'yaml';
import { AppModule } from '../src/app.module';
import { buildOpenApi, setupApp } from '../src/setup-app';

/** Exporta el contrato OpenAPI a apps/api/openapi.yaml sin levantar el servidor. */
async function main(): Promise<void> {
  const app = await NestFactory.create(AppModule, { logger: false, abortOnError: false });
  setupApp(app);
  await app.init();
  const file = join(__dirname, '..', 'openapi.yaml');
  writeFileSync(file, stringify(buildOpenApi(app), { aliasDuplicateObjects: false }));
  await app.close();
  console.log(`OpenAPI exportado en ${file}`);
}

void main();
