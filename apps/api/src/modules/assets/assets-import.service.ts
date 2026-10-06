import { createHash } from 'node:crypto';
import { BadRequestException, Injectable } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { parse as parseCsv } from 'csv-parse/sync';
import { validate } from 'class-validator';
import { SiteStatus } from '@prisma/client';
import { readSheet } from 'read-excel-file/node';
import type { AuthUser } from '../auth/auth.types';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateAssetDto } from './dto/assets.dto';
import { AssetsService } from './assets.service';

const TEMPLATE =
  'type,name,description,initialQuantity,siteName,status\nHERRAMIENTA,Pala de punta,Pala reforzada,3,Almacén central,OPERATIVO\n';
const MAX_ROWS = 500;

export interface UploadedAssetFile {
  originalname: string;
  buffer: Buffer;
}

@Injectable()
export class AssetsImportService {
  constructor(
    private readonly assets: AssetsService,
    private readonly prisma: PrismaService,
  ) {}

  template(): string {
    return TEMPLATE;
  }

  async import(file: UploadedAssetFile, idempotencyKey: string, actor: AuthUser, ip?: string) {
    const extension = file.originalname.toLowerCase().split('.').pop();
    if (extension !== 'csv' && extension !== 'xlsx') {
      throw new BadRequestException('El archivo debe ser CSV o XLSX');
    }
    const rows = await this.readRows(file.buffer, extension);
    if (rows.length === 0) throw new BadRequestException('El archivo no contiene filas');
    if (rows.length - 1 > MAX_ROWS) {
      throw new BadRequestException(`El archivo admite hasta ${MAX_ROWS} activos por carga`);
    }

    const headers = rows[0].map((cell) =>
      String(cell ?? '')
        .trim()
        .replace(/^\uFEFF/, '')
        .toLowerCase(),
    );
    const requiredHeaders = ['type', 'name', 'initialquantity'];
    const missingHeaders = requiredHeaders.filter((header) => !headers.includes(header));
    if (missingHeaders.length) {
      throw new BadRequestException(`Faltan columnas requeridas: ${missingHeaders.join(', ')}`);
    }
    if (!headers.includes('initialsiteid') && !headers.includes('sitename')) {
      throw new BadRequestException('Incluye la columna initialSiteId o siteName');
    }
    if (new Set(headers).size !== headers.length) {
      throw new BadRequestException('El encabezado contiene columnas duplicadas');
    }

    const column = new Map(headers.map((header, index) => [header, index]));
    const siteNameColumn = column.get('sitename');
    const requestedSiteNames = new Set(
      rows
        .slice(1)
        .map((row) => String(row[siteNameColumn ?? -1] ?? '').trim())
        .filter(Boolean),
    );
    const siteRows = requestedSiteNames.size
      ? await this.prisma.site.findMany({
          where: {
            status: SiteStatus.ACTIVA,
            name: { in: [...requestedSiteNames], mode: 'insensitive' },
          },
          select: { id: true, name: true },
        })
      : [];
    const sitesByName = new Map<string, string[]>();
    for (const site of siteRows) {
      const key = site.name.trim().toLocaleLowerCase();
      const matching = sitesByName.get(key);
      if (matching) matching.push(site.id);
      else sitesByName.set(key, [site.id]);
    }

    const batchPrefix = createHash('sha256').update(idempotencyKey).digest('hex');
    const results: {
      row: number;
      status: 'CREATED' | 'ERROR';
      assetId?: string;
      code?: string;
      errors?: string[];
    }[] = [];

    for (const [index, row] of rows.slice(1).entries()) {
      const rowNumber = index + 2;
      if (row.every((cell) => cell === null || String(cell ?? '').trim() === '')) continue;
      const value = (key: string) => row[column.get(key) ?? -1];
      const quantity = Number(value('initialquantity'));
      let initialSiteId = String(value('initialsiteid') ?? '').trim();
      const siteName = String(value('sitename') ?? '').trim();
      if (!initialSiteId && siteName) {
        const matchingSites = sitesByName.get(siteName.toLocaleLowerCase()) ?? [];
        if (matchingSites.length !== 1) {
          results.push({
            row: rowNumber,
            status: 'ERROR',
            errors: [
              matchingSites.length === 0
                ? 'siteName: no se encontró una ubicación activa con ese nombre'
                : 'siteName: el nombre coincide con varias ubicaciones; usa initialSiteId',
            ],
          });
          continue;
        }
        initialSiteId = matchingSites[0];
      }
      const dto = plainToInstance(CreateAssetDto, {
        type: String(value('type') ?? '')
          .trim()
          .toUpperCase(),
        name: String(value('name') ?? ''),
        description: String(value('description') ?? '').trim() || undefined,
        initialQuantity: quantity,
        initialSiteId,
        status:
          String(value('status') ?? '')
            .trim()
            .toUpperCase() || undefined,
      });
      const validation = await validate(dto);
      if (validation.length) {
        results.push({
          row: rowNumber,
          status: 'ERROR',
          errors: validation.flatMap((item) =>
            Object.values(item.constraints ?? {}).map((message) => `${item.property}: ${message}`),
          ),
        });
        continue;
      }

      const rowKey = createHash('sha256').update(`${batchPrefix}:${rowNumber}`).digest('hex');
      try {
        const asset = await this.assets.create(dto, rowKey, actor, ip);
        results.push({ row: rowNumber, status: 'CREATED', assetId: asset.id, code: asset.code });
      } catch (error) {
        const message = error instanceof Error ? error.message : 'No se pudo crear el activo';
        results.push({ row: rowNumber, status: 'ERROR', errors: [message] });
      }
    }

    return {
      rows: results,
      totalRows: results.length,
      created: results.filter((row) => row.status === 'CREATED').length,
      failed: results.filter((row) => row.status === 'ERROR').length,
    };
  }

  private async readRows(buffer: Buffer, extension: string): Promise<unknown[][]> {
    try {
      if (extension === 'xlsx') {
        return (await readSheet(buffer)) as unknown[][];
      }
      const text = buffer.toString('utf8');
      const firstLine = text.split(/\r?\n/, 1)[0] ?? '';
      const delimiter = firstLine.includes(';') && !firstLine.includes(',') ? ';' : ',';
      return parseCsv(text, {
        bom: true,
        delimiter,
        skip_empty_lines: true,
        relax_column_count: true,
      }) as unknown[][];
    } catch {
      throw new BadRequestException('No se pudo leer el archivo; revisa que sea CSV o XLSX válido');
    }
  }
}
