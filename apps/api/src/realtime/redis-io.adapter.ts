import type { INestApplication } from '@nestjs/common';
import { IoAdapter } from '@nestjs/platform-socket.io';
import { createAdapter } from '@socket.io/redis-adapter';
import Redis from 'ioredis';
import type { Server, ServerOptions } from 'socket.io';

export class RedisIoAdapter extends IoAdapter {
  private readonly pubClient: Redis;
  private readonly subClient: Redis;

  private constructor(
    app: INestApplication,
    redis: Redis,
    private readonly origins: string[],
  ) {
    super(app);
    this.pubClient = redis.duplicate();
    this.subClient = this.pubClient.duplicate();
  }

  static async create(
    app: INestApplication,
    redis: Redis,
    origins: string[],
  ): Promise<RedisIoAdapter> {
    const adapter = new RedisIoAdapter(app, redis, origins);
    await Promise.all([adapter.pubClient.connect(), adapter.subClient.connect()]);
    return adapter;
  }

  override createIOServer(port: number, options?: ServerOptions): Server {
    const server = super.createIOServer(port, {
      ...options,
      cors: { origin: this.origins, credentials: false },
    }) as Server;
    server.adapter(createAdapter(this.pubClient, this.subClient));
    return server;
  }

  override async close(server: Server): Promise<void> {
    try {
      await super.close(server);
    } finally {
      await Promise.all([
        this.pubClient.quit().catch(() => this.pubClient.disconnect()),
        this.subClient.quit().catch(() => this.subClient.disconnect()),
      ]);
    }
  }
}
