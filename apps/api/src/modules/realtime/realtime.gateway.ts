import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import {
  OnGatewayConnection,
  OnGatewayInit,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import type { Role } from '@prisma/client';
import type { Namespace, Socket } from 'socket.io';
import { PrismaService } from '../../prisma/prisma.service';
import type { AccessTokenPayload } from '../auth/auth.types';

export type RealtimeEvent =
  | 'movement.created'
  | 'stock.updated'
  | 'site.updated'
  | 'asset.updated'
  | 'session.revoked';

@Injectable()
@WebSocketGateway({ namespace: '/realtime', transports: ['websocket'] })
export class RealtimeGateway implements OnGatewayInit, OnGatewayConnection {
  @WebSocketServer()
  private server?: Namespace;

  constructor(
    private readonly jwt: JwtService,
    private readonly prisma: PrismaService,
  ) {}

  afterInit(server: Namespace): void {
    server.use((client, next) => {
      void this.authenticate(client).then(
        () => next(),
        () => next(new Error('NO_AUTENTICADO')),
      );
    });
  }

  async handleConnection(client: Socket): Promise<void> {
    const userId = client.data.userId as string | undefined;
    if (!userId) {
      client.disconnect(true);
      return;
    }
    await client.join([`user:${userId}`, 'inventory']);
    client.emit('realtime.ready', { connectedAt: new Date().toISOString() });
  }

  private async authenticate(client: Socket): Promise<void> {
    const token = client.handshake.auth?.token;
    if (typeof token !== 'string' || token.length === 0) {
      throw new Error('Missing token');
    }
    const payload = await this.jwt.verifyAsync<AccessTokenPayload>(token, {
      algorithms: ['RS256'],
    });
    if (payload.mcp) throw new Error('Password change required');
    const [user, session] = await Promise.all([
      this.prisma.user.findUnique({
        where: { id: payload.sub },
        select: { id: true, role: true, active: true },
      }),
      this.prisma.refreshToken.findFirst({
        where: {
          userId: payload.sub,
          familyId: payload.sid,
          revokedAt: null,
          expiresAt: { gt: new Date() },
        },
        select: { id: true },
      }),
    ]);
    if (!user?.active || !session) throw new Error('Session revoked');

    client.data.userId = user.id;
    client.data.role = user.role as Role;
    client.data.sessionId = payload.sid;
  }

  publish(event: RealtimeEvent, payload: Record<string, unknown>): void {
    this.server?.to('inventory').emit(event, payload);
  }

  revokeSession(userId: string, sessionId?: string): void {
    this.server?.to(`user:${userId}`).emit('session.revoked', {
      ...(sessionId ? { sessionId } : {}),
    });
  }
}
