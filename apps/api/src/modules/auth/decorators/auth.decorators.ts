import { createParamDecorator, ExecutionContext, SetMetadata } from '@nestjs/common';
import type { Role } from '@prisma/client';
import type { AuthUser } from '../auth.types';

export const IS_PUBLIC = 'isPublic';
export const ROLES = 'roles';
export const ALLOW_PENDING_PASSWORD = 'allowPendingPassword';

/** El endpoint no requiere access token. */
export const Public = () => SetMetadata(IS_PUBLIC, true);

/** Roles permitidos (docs/07 §4). Sin decorador: cualquier usuario autenticado. */
export const Roles = (...roles: Role[]) => SetMetadata(ROLES, roles);

/** Permitido aunque el usuario aún deba cambiar su contraseña temporal. */
export const AllowPendingPassword = () => SetMetadata(ALLOW_PENDING_PASSWORD, true);

export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): AuthUser =>
    ctx.switchToHttp().getRequest<{ user: AuthUser }>().user,
);
