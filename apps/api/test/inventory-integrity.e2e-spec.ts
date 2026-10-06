import { INestApplication } from '@nestjs/common';
import { AssetType } from '@prisma/client';
import { InventoryIntegrityService } from '../src/modules/integrity/inventory-integrity.service';
import { PrismaService } from '../src/prisma/prisma.service';
import { createTestApp } from './helpers';

describe('Verificación de invariantes del inventario', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let integrity: InventoryIntegrityService;

  beforeAll(async () => {
    app = await createTestApp();
    prisma = app.get(PrismaService);
    integrity = app.get(InventoryIntegrityService);
  });

  afterAll(() => app.close());

  it('detecta activos cuyo stock por ubicación no cuadra con el total', async () => {
    const code = `HER${Date.now().toString().slice(-9)}`;
    const asset = await prisma.asset.create({
      data: {
        code,
        type: AssetType.HERRAMIENTA,
        name: 'Activo inconsistente de QA',
        totalStock: 3,
      },
    });

    const report = await integrity.inspect();

    expect(report.assetStockMismatches).toContainEqual({
      assetId: asset.id,
      code,
      expected: 3,
      actual: 0,
    });
    expect(report.checkedAt).toMatch(/^\d{4}-\d\d-\d\dT/);
  });
});
