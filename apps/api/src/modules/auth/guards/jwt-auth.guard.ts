import { CanActivate, ExecutionContext, HttpStatus, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import type { Request } from 'express';
import { DomainException } from '../../../common/filters/problem-details.filter';
import type { AccessTokenPayload, AuthUser } from '../auth.types';
import { ALLOW_PENDING_PASSWORD, IS_PUBLIC } from '../decorators/auth.decorators';

/** Guarda global: exige un access token válido salvo en endpoints `@Public()`. */
@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly jwt: JwtService,
    private readonly reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const targets = [context.getHandler(), context.getClass()];
    if (this.reflector.getAllAndOverride<boolean>(IS_PUBLIC, targets)) return true;

    const req = context.switchToHttp().getRequest<Request & { user?: AuthUser }>();
    const [scheme, token] = (req.headers.authorization ?? '').split(' ');
    if (scheme !== 'Bearer' || !token) throw unauthenticated();

    let payload: AccessTokenPayload;
    try {
      payload = await this.jwt.verifyAsync<AccessTokenPayload>(token, { algorithms: ['RS256'] });
    } catch {
      throw unauthenticated();
    }

    req.user = {
      id: payload.sub,
      role: payload.role,
      sessionId: payload.sid,
      mustChangePassword: payload.mcp,
    };

    if (payload.mcp && !this.reflector.getAllAndOverride<boolean>(ALLOW_PENDING_PASSWORD, targets)) {
      throw new DomainException(
        'CAMBIO_CLAVE_REQUERIDO',
        'Debes cambiar tu contraseña temporal',
        HttpStatus.FORBIDDEN,
      );
    }
    return true;
  }
}

function unauthenticated(): DomainException {
  return new DomainException('NO_AUTENTICADO', 'Sesión inválida o vencida', HttpStatus.UNAUTHORIZED);
}
