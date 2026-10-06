import { Controller, Get, Inject } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import {
  HealthCheck,
  HealthCheckService,
  HealthIndicatorService,
  PrismaHealthIndicator,
} from '@nestjs/terminus';
import type Redis from 'ioredis';
import { PrismaService } from '../../prisma/prisma.service';
import { Public } from '../auth/decorators/auth.decorators';
import { REDIS } from '../../redis/redis.module';

@ApiTags('health')
@Public()
@Controller('health')
export class HealthController {
  constructor(
    private readonly health: HealthCheckService,
    private readonly prismaIndicator: PrismaHealthIndicator,
    private readonly indicators: HealthIndicatorService,
    private readonly prisma: PrismaService,
    @Inject(REDIS) private readonly redis: Redis,
  ) {}

  /** El proceso está vivo. */
  @Get('live')
  live(): { status: 'ok' } {
    return { status: 'ok' };
  }

  /** Listo para recibir tráfico: PostgreSQL y Redis responden. */
  @Get('ready')
  @HealthCheck()
  ready() {
    return this.health.check([
      () => this.prismaIndicator.pingCheck('database', this.prisma, { timeout: 1500 }),
      async () => {
        const indicator = this.indicators.check('redis');
        try {
          if (this.redis.status === 'wait') await this.redis.connect();
          await this.redis.ping();
          return indicator.up();
        } catch (e) {
          return indicator.down({ message: (e as Error).message });
        }
      },
    ]);
  }
}
