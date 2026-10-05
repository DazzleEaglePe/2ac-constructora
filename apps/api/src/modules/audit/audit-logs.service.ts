import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import type { ListAuditLogsQuery } from './audit-logs.dto';

@Injectable()
export class AuditLogsService {
  constructor(private readonly prisma: PrismaService) {}

  async list(query: ListAuditLogsQuery) {
    const where: Prisma.AuditLogWhereInput = {
      userId: query.userId,
      action: query.action,
      entityType: query.entityType,
      ...(query.from || query.to ? { createdAt: {
        ...(query.from ? { gte: new Date(query.from) } : {}),
        ...(query.to ? { lte: new Date(query.to) } : {}),
      } } : {}),
    };
    const limit = 50;
    const rows = await this.prisma.auditLog.findMany({
      where,
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
      ...(query.cursor ? { cursor: { id: query.cursor }, skip: 1 } : {}),
      include: { user: { select: { id: true, fullName: true, dni: true } } },
    });
    const data = rows.slice(0, limit);
    return {
      data,
      nextCursor: rows.length > limit ? data[data.length - 1].id : null,
    };
  }
}
