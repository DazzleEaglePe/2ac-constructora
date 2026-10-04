import { CanActivate, ExecutionContext, HttpStatus, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Role } from '@prisma/client';
import { DomainException } from '../../../common/filters/problem-details.filter';
import type { AuthUser } from '../auth.types';
import { ROLES } from '../decorators/auth.decorators';

/** Guarda global de roles. La decisión siempre la toma el servidor (docs/07 §4). */
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const roles = this.reflector.getAllAndOverride<Role[] | undefined>(ROLES, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!roles?.length) return true;
    const user = context.switchToHttp().getRequest<{ user?: AuthUser }>().user;
    if (user && roles.includes(user.role)) return true;
    throw new DomainException('SIN_PERMISO', 'No tienes permiso para esta acción', HttpStatus.FORBIDDEN);
  }
}
