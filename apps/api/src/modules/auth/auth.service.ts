import { HttpStatus, Injectable } from '@nestjs/common';
import { DomainException } from '../../common/filters/problem-details.filter';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { RealtimeGateway } from '../realtime/realtime.gateway';
import { toUserView, UserView } from '../users/user.view';
import { PasswordService } from './password.service';
import { hashToken, TokenPair, TokenService } from './token.service';

export const MAX_FAILED_ATTEMPTS = 5;
export const LOCK_MINUTES = 15;

export interface LoginResult extends TokenPair {
  user: UserView;
}

const invalidCredentials = () =>
  new DomainException(
    'CREDENCIALES_INVALIDAS',
    'DNI o contraseña incorrectos',
    HttpStatus.UNAUTHORIZED,
  );

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly passwords: PasswordService,
    private readonly tokens: TokenService,
    private readonly audit: AuditService,
    private readonly realtime: RealtimeGateway,
  ) {}

  /** RF-AUT-01 / RF-AUT-04: ingreso por DNI con bloqueo tras 5 intentos fallidos. */
  async login(dni: string, password: string, deviceName?: string, ip?: string): Promise<LoginResult> {
    const user = await this.prisma.user.findUnique({ where: { dni } });

    if (user?.lockedUntil && user.lockedUntil > new Date()) {
      throw new DomainException(
        'CUENTA_BLOQUEADA',
        'Cuenta bloqueada temporalmente por intentos fallidos',
        HttpStatus.LOCKED,
        `Vuelve a intentar después de las ${user.lockedUntil.toISOString()}`,
        { lockedUntil: user.lockedUntil.toISOString() },
      );
    }

    // Se verifica siempre (aunque el DNI no exista) para no revelar cuentas por el tiempo de respuesta.
    const ok = await this.passwords.verify(user?.passwordHash ?? null, password);
    if (!user) throw invalidCredentials();

    if (!ok) {
      const attempts = user.failedAttempts + 1;
      if (attempts >= MAX_FAILED_ATTEMPTS) {
        const lockedUntil = new Date(Date.now() + LOCK_MINUTES * 60_000);
        await this.prisma.$transaction(async (tx) => {
          await tx.user.update({ where: { id: user.id }, data: { failedAttempts: 0, lockedUntil } });
          await this.audit.log(
            { userId: user.id, action: 'LOGIN_LOCKED', entityType: 'user', entityId: user.id, ip },
            tx,
          );
        });
      } else {
        await this.prisma.user.update({ where: { id: user.id }, data: { failedAttempts: attempts } });
      }
      throw invalidCredentials();
    }

    if (!user.active) {
      throw new DomainException(
        'CUENTA_DESACTIVADA',
        'Tu cuenta está desactivada. Contacta al administrador.',
        HttpStatus.FORBIDDEN,
      );
    }

    if (user.mustChangePassword && user.tempPasswordExpiresAt && user.tempPasswordExpiresAt < new Date()) {
      throw new DomainException(
        'CLAVE_TEMPORAL_VENCIDA',
        'Tu contraseña temporal venció. Pide al administrador una nueva.',
        HttpStatus.FORBIDDEN,
      );
    }

    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.user.update({
        where: { id: user.id },
        data: { failedAttempts: 0, lockedUntil: null, lastLoginAt: new Date() },
      });
      const pair = await this.tokens.issue(updated, { deviceName }, tx);
      return { ...pair, user: toUserView(updated) };
    });
  }

  /** Rotación del refresh token con detección de reutilización (docs/07 §3). */
  async refresh(refreshToken: string): Promise<TokenPair> {
    const stored = await this.prisma.refreshToken.findUnique({
      where: { tokenHash: hashToken(refreshToken) },
      include: { user: true },
    });
    const invalid = new DomainException('NO_AUTENTICADO', 'Sesión inválida o vencida', HttpStatus.UNAUTHORIZED);
    if (!stored) throw invalid;

    if (stored.revokedAt) {
      // Reutilización de un token ya rotado: posible robo → se cierra toda la sesión.
      await this.tokens.revokeFamily(stored.familyId);
      this.realtime.revokeSession(stored.userId, stored.familyId);
      throw invalid;
    }
    if (stored.expiresAt < new Date() || !stored.user.active) throw invalid;

    return this.prisma.$transaction(async (tx) => {
      const { count } = await tx.refreshToken.updateMany({
        where: { id: stored.id, revokedAt: null },
        data: { revokedAt: new Date() },
      });
      if (count === 0) throw invalid; // carrera: otro refresh usó este token primero
      return this.tokens.issue(stored.user, { familyId: stored.familyId, deviceName: stored.deviceName ?? undefined }, tx);
    });
  }

  /** Cierra la sesión del dispositivo (revoca la familia del refresh token). */
  async logout(refreshToken: string): Promise<void> {
    const stored = await this.prisma.refreshToken.findUnique({
      where: { tokenHash: hashToken(refreshToken) },
    });
    if (stored) {
      await this.tokens.revokeFamily(stored.familyId);
      this.realtime.revokeSession(stored.userId, stored.familyId);
    }
  }

  /** RF-AUT-05 / RF-USR-07: cambio de contraseña propia (incluida la temporal). */
  async changePassword(
    userId: string,
    sessionId: string,
    currentPassword: string,
    newPassword: string,
  ): Promise<TokenPair> {
    const user = await this.prisma.user.findUniqueOrThrow({ where: { id: userId } });
    if (!(await this.passwords.verify(user.passwordHash, currentPassword))) {
      throw new DomainException(
        'CREDENCIALES_INVALIDAS',
        'La contraseña actual no es correcta',
        HttpStatus.UNAUTHORIZED,
      );
    }
    this.passwords.assertPolicy(newPassword, user.dni);
    if (currentPassword === newPassword) {
      throw new DomainException(
        'VALIDACION',
        'La nueva contraseña debe ser distinta de la actual',
        HttpStatus.UNPROCESSABLE_ENTITY,
      );
    }
    const passwordHash = await this.passwords.hash(newPassword);

    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.user.update({
        where: { id: userId },
        data: { passwordHash, mustChangePassword: false, tempPasswordExpiresAt: null },
      });
      // Las demás sesiones se cierran; la actual recibe tokens nuevos sin la marca de cambio pendiente.
      await this.tokens.revokeAllForUser(userId, tx);
      return this.tokens.issue(updated, { familyId: sessionId }, tx);
    });
  }

  async me(userId: string): Promise<UserView> {
    const user = await this.prisma.user.findUniqueOrThrow({ where: { id: userId } });
    return toUserView(user);
  }
}
