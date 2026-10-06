import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import type { Prisma, User } from '@prisma/client';
import type { Env } from '../../config/env.schema';
import { PrismaService } from '../../prisma/prisma.service';
import type { AccessTokenPayload } from './auth.types';

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

export const hashToken = (token: string): string =>
  createHash('sha256').update(token).digest('hex');

/** Emisión y rotación de tokens (docs/07 §3). */
@Injectable()
export class TokenService {
  constructor(
    private readonly jwt: JwtService,
    private readonly prisma: PrismaService,
    private readonly config: ConfigService<Env, true>,
  ) {}

  /** Crea un par nuevo. Sin `familyId`, inicia una sesión nueva. */
  async issue(
    user: Pick<User, 'id' | 'role' | 'mustChangePassword'>,
    opts: { familyId?: string; deviceName?: string } = {},
    tx: Prisma.TransactionClient = this.prisma,
  ): Promise<TokenPair> {
    const familyId = opts.familyId ?? randomUUID();
    const refreshToken = `rt_${randomBytes(32).toString('base64url')}`;
    const days = this.config.get('REFRESH_TTL_DAYS', { infer: true });

    await tx.refreshToken.create({
      data: {
        userId: user.id,
        tokenHash: hashToken(refreshToken),
        familyId,
        deviceName: opts.deviceName,
        expiresAt: new Date(Date.now() + days * 86_400_000),
      },
    });

    const payload: AccessTokenPayload = {
      sub: user.id,
      role: user.role,
      sid: familyId,
      mcp: user.mustChangePassword,
    };
    const accessToken = await this.jwt.signAsync(payload);
    return { accessToken, refreshToken };
  }

  /** Revoca todas las sesiones (familias) de un usuario. */
  async revokeAllForUser(userId: string, tx: Prisma.TransactionClient = this.prisma): Promise<void> {
    await tx.refreshToken.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }

  async revokeFamily(familyId: string, tx: Prisma.TransactionClient = this.prisma): Promise<void> {
    await tx.refreshToken.updateMany({
      where: { familyId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }
}
