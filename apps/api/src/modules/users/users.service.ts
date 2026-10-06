import { HttpStatus, Injectable } from '@nestjs/common';
import { Prisma, Role, User } from '@prisma/client';
import { DomainException } from '../../common/filters/problem-details.filter';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import type { AuthUser } from '../auth/auth.types';
import { PasswordService } from '../auth/password.service';
import { TokenService } from '../auth/token.service';
import { RealtimeGateway } from '../realtime/realtime.gateway';
import type { CreateUserDto, ListUsersQuery, UpdateUserDto } from './dto/users.dto';
import { toUserView, UserView } from './user.view';

const TEMP_PASSWORD_HOURS = 72;

const notFound = () =>
  new DomainException('NO_ENCONTRADO', 'Usuario no encontrado', HttpStatus.NOT_FOUND);

/** Gestión de usuarios: solo administradores (RF-USR-01…05). */
@Injectable()
export class UsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly passwords: PasswordService,
    private readonly tokens: TokenService,
    private readonly audit: AuditService,
    private readonly realtime: RealtimeGateway,
  ) {}

  async list(query: ListUsersQuery): Promise<{ data: UserView[]; nextCursor: string | null }> {
    const limit = query.limit ?? 50;
    const where: Prisma.UserWhereInput = {
      role: query.role,
      active: query.active,
      ...(query.q
        ? {
            OR: [
              { fullName: { contains: query.q, mode: 'insensitive' } },
              { dni: { startsWith: query.q } },
            ],
          }
        : {}),
    };
    const users = await this.prisma.user.findMany({
      where,
      orderBy: [{ fullName: 'asc' }, { id: 'asc' }],
      take: limit + 1,
      ...(query.cursor ? { cursor: { id: query.cursor }, skip: 1 } : {}),
    });
    const page = users.slice(0, limit);
    const last = await this.lastMovements(page.map((u) => u.id));
    return {
      data: page.map((u) => toUserView(u, last.get(u.id) ?? null)),
      nextCursor: users.length > limit ? page[page.length - 1].id : null,
    };
  }

  async get(id: string): Promise<UserView> {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) throw notFound();
    const last = await this.lastMovements([id]);
    return toUserView(user, last.get(id) ?? null);
  }

  async create(dto: CreateUserDto, actor: AuthUser, ip?: string): Promise<UserView> {
    this.passwords.assertPolicy(dto.temporaryPassword, dto.dni);
    const exists = await this.prisma.user.findUnique({ where: { dni: dto.dni } });
    if (exists) {
      throw new DomainException('DNI_DUPLICADO', 'Ya existe un usuario con ese DNI', HttpStatus.CONFLICT);
    }
    const passwordHash = await this.passwords.hash(dto.temporaryPassword);
    return this.prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          dni: dto.dni,
          fullName: dto.fullName,
          role: dto.role,
          passwordHash,
          mustChangePassword: true,
          tempPasswordExpiresAt: tempExpiry(),
        },
      });
      await this.audit.log(
        {
          userId: actor.id,
          action: 'USER_CREATED',
          entityType: 'user',
          entityId: user.id,
          after: snapshot(user),
          ip,
        },
        tx,
      );
      return toUserView(user);
    });
  }

  async update(id: string, dto: UpdateUserDto, actor: AuthUser, ip?: string): Promise<UserView> {
    const before = await this.findOrThrow(id);
    if (dto.role && dto.role !== Role.ADMIN && before.role === Role.ADMIN) {
      await this.assertNotLastAdmin(id);
    }
    const updated = await this.prisma.$transaction(async (tx) => {
      const user = await tx.user.update({ where: { id }, data: dto });
      if (dto.role && dto.role !== before.role) {
        // El rol viaja en el access token: se cierran sus sesiones para que tome efecto ya.
        await this.tokens.revokeAllForUser(id, tx);
      }
      await this.audit.log(
        {
          userId: actor.id,
          action: 'USER_UPDATED',
          entityType: 'user',
          entityId: id,
          before: snapshot(before),
          after: snapshot(user),
          ip,
        },
        tx,
      );
      return toUserView(user);
    });
    if (dto.role && dto.role !== before.role) this.realtime.revokeSession(id);
    return updated;
  }

  async setActive(id: string, active: boolean, actor: AuthUser, ip?: string): Promise<UserView> {
    const before = await this.findOrThrow(id);
    if (!active) {
      if (id === actor.id) {
        throw new DomainException(
          'NO_PUEDES_DESACTIVARTE',
          'No puedes desactivar tu propia cuenta',
          HttpStatus.CONFLICT,
        );
      }
      if (before.role === Role.ADMIN) await this.assertNotLastAdmin(id);
    }
    const updated = await this.prisma.$transaction(async (tx) => {
      const user = await tx.user.update({ where: { id }, data: { active } });
      if (!active) await this.tokens.revokeAllForUser(id, tx); // RN-13
      await this.audit.log(
        {
          userId: actor.id,
          action: active ? 'USER_ACTIVATED' : 'USER_DEACTIVATED',
          entityType: 'user',
          entityId: id,
          ip,
        },
        tx,
      );
      return toUserView(user);
    });
    if (!active) this.realtime.revokeSession(id);
    return updated;
  }

  /** RF-USR-05: genera una contraseña temporal que se muestra una sola vez. */
  async resetPassword(id: string, actor: AuthUser, ip?: string): Promise<{ temporaryPassword: string }> {
    await this.findOrThrow(id);
    const temporaryPassword = this.passwords.generateTemporary();
    const passwordHash = await this.passwords.hash(temporaryPassword);
    await this.prisma.$transaction(async (tx) => {
      await tx.user.update({
        where: { id },
        data: {
          passwordHash,
          mustChangePassword: true,
          tempPasswordExpiresAt: tempExpiry(),
          failedAttempts: 0,
          lockedUntil: null,
        },
      });
      await this.tokens.revokeAllForUser(id, tx);
      await this.audit.log(
        { userId: actor.id, action: 'USER_PASSWORD_RESET', entityType: 'user', entityId: id, ip },
        tx,
      );
    });
    this.realtime.revokeSession(id);
    return { temporaryPassword };
  }

  private async findOrThrow(id: string): Promise<User> {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) throw notFound();
    return user;
  }

  private async assertNotLastAdmin(id: string): Promise<void> {
    const others = await this.prisma.user.count({
      where: { role: Role.ADMIN, active: true, id: { not: id } },
    });
    if (others === 0) {
      throw new DomainException(
        'ULTIMO_ADMINISTRADOR',
        'Debe quedar al menos un administrador activo',
        HttpStatus.CONFLICT,
      );
    }
  }

  private async lastMovements(userIds: string[]): Promise<Map<string, Date>> {
    if (!userIds.length) return new Map();
    const rows = await this.prisma.movement.groupBy({
      by: ['userId'],
      where: { userId: { in: userIds } },
      _max: { createdAt: true },
    });
    return new Map(rows.flatMap((r) => (r._max.createdAt ? [[r.userId, r._max.createdAt]] : [])));
  }
}

const tempExpiry = () => new Date(Date.now() + TEMP_PASSWORD_HOURS * 3_600_000);

const snapshot = (u: User) => ({ dni: u.dni, fullName: u.fullName, role: u.role, active: u.active });
