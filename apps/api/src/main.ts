import 'reflect-metadata';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';
import type { Env } from './config/env.schema';
import { buildOpenApi, setupApp } from './setup-app';
import { REDIS } from './redis/redis.module';
import Redis from 'ioredis';
import { RedisIoAdapter } from './realtime/redis-io.adapter';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule, { bufferLogs: true });
  setupApp(app);
  const config = app.get(ConfigService<Env, true>);
  const socketAdapter = await RedisIoAdapter.create(
    app,
    app.get<Redis>(REDIS),
    config.get('CORS_ORIGINS', { infer: true }),
  );
  app.useWebSocketAdapter(socketAdapter);
  if (config.get('NODE_ENV', { infer: true }) !== 'production') {
    SwaggerModule.setup('docs', app, buildOpenApi(app));
  }
  await app.listen(config.get('PORT', { infer: true }));
}

void bootstrap();
