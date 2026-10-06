import 'package:a2c_inventario/core/storage/local_database.dart';
import 'package:a2c_inventario/core/storage/offline_movements.dart';
import 'package:a2c_inventario/features/assets/domain/asset.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LocalDatabase database;

  setUp(() => database = LocalDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test('stores cached JSON and returns it after a read', () async {
    final response = {
      'items': [
        {'id': 'asset-1', 'quantity': 3},
      ],
    };

    await database.putCache('inventory', response);

    expect(await database.getCache('inventory'), response);
    expect(await database.watchLatestCacheFetchedAt().first, isNotNull);
  });

  test('keeps pending movement status, identity, and retry count', () async {
    await database.enqueueMovement(
      id: 'local-1',
      ownerId: 'user-1',
      idempotencyKey: 'request-1',
      payload: const {'assetId': 'asset-1', 'quantity': 2},
    );

    final queued = await database.pendingForSync('user-1');
    expect(queued.single.idempotencyKey, 'request-1');
    expect(queued.single.status, 'PENDIENTE');

    await database.setMovementStatus(
      queued.single.id,
      status: 'PENDIENTE',
      incrementAttempts: true,
    );
    final retried = await database.pendingForSync('user-1');
    expect(retried.single.attempts, 1);
    expect(retried.single.idempotencyKey, 'request-1');
  });

  test(
    'projects pending stock optimistically and rolls it back on rejection',
    () async {
      await database.enqueueMovement(
        id: 'local-2',
        ownerId: 'user-1',
        idempotencyKey: 'request-2',
        payload: const {
          'assetId': 'asset-1',
          'fromSiteId': 'site-1',
          'toSiteId': 'site-2',
          'quantity': 2,
        },
      );
      const asset = Asset(
        id: 'asset-1',
        code: 'HER-001',
        type: 'HERRAMIENTA',
        name: 'Pala',
        description: null,
        status: 'OPERATIVO',
        totalStock: 5,
        distribution: [
          AssetDistribution(
            siteId: 'site-1',
            siteName: 'Almacén',
            siteType: 'ALMACEN',
            quantity: 5,
          ),
        ],
        notesCount: 0,
      );

      final pending = await database.pendingForSync('user-1');
      final projected = applyPendingMovementsToAsset(asset, pending);
      expect(
        projected.distribution
            .firstWhere((row) => row.siteId == 'site-1')
            .quantity,
        3,
      );
      expect(
        projected.distribution
            .firstWhere((row) => row.siteId == 'site-2')
            .quantity,
        2,
      );

      await database.setMovementStatus('local-2', status: 'RECHAZADO');
      final rejected = await database.watchMovements('user-1').first;
      final rolledBack = applyPendingMovementsToAsset(asset, rejected);
      expect(rolledBack.distribution.single.quantity, 5);
    },
  );
}
