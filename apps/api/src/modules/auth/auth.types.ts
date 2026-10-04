import type { Role } from '@prisma/client';

/** Claims del access token (JWT RS256). */
export interface AccessTokenPayload {
  sub: string;
  role: Role;
  /** Familia de refresh tokens (sesión del dispositivo). */
  sid: string;
  /** Debe cambiar la contraseña temporal antes de usar la app. */
  mcp: boolean;
}

/** Usuario autenticado disponible en `request.user`. */
export interface AuthUser {
  id: string;
  role: Role;
  sessionId: string;
  mustChangePassword: boolean;
}
