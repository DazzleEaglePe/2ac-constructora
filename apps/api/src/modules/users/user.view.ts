import type { Role, User } from '@prisma/client';

/** Representación pública de un usuario (sin hash ni datos internos). */
export interface UserView {
  id: string;
  dni: string;
  fullName: string;
  role: Role;
  active: boolean;
  mustChangePassword: boolean;
  lastLoginAt: string | null;
  lastMovementAt: string | null;
  createdAt: string;
}

export function toUserView(user: User, lastMovementAt: Date | null = null): UserView {
  return {
    id: user.id,
    dni: user.dni,
    fullName: user.fullName,
    role: user.role,
    active: user.active,
    mustChangePassword: user.mustChangePassword,
    lastLoginAt: user.lastLoginAt?.toISOString() ?? null,
    lastMovementAt: lastMovementAt?.toISOString() ?? null,
    createdAt: user.createdAt.toISOString(),
  };
}
