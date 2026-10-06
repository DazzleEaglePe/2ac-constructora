import 'dart:async';

import 'package:a2c_inventario/core/network/api_failure.dart';
import 'package:a2c_inventario/core/storage/local_database.dart';
import 'package:a2c_inventario/core/storage/offline_movements.dart';
import 'package:a2c_inventario/features/auth/application/session_controller.dart';
import 'package:a2c_inventario/features/auth/domain/app_user.dart';
import 'package:a2c_inventario/features/movements/data/movements_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class _MovementsRepository extends Mock implements MovementsRepository {}

class _ConnectivityMonitor implements ConnectivityMonitor {
  final changes = StreamController<List<ConnectivityResult>>.broadcast(
    sync: true,
  );

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => [
    ConnectivityResult.none,
  ];

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => changes.stream;
}

void main() {
  late LocalDatabase database;
  late _MovementsRepository api;
  late OfflineMovementQueue queue;

  setUp(() {
    database = LocalDatabase(NativeDatabase.memory());
    api = _MovementsRepository();
    queue = OfflineMovementQueue(database, api);
  });

  tearDown(() async {
    await database.close();
  });

  test('sends queued movement with its stable idempotency key', () async {
    await database.enqueueMovement(
      id: 'local-1',
      ownerId: 'user-1',
      idempotencyKey: 'request-1',
      payload: const {
        'assetId': 'asset-1',
        'fromSiteId': 'site-1',
        'toSiteId': 'site-2',
        'quantity': 2,
      },
    );
    when(
      () => api.transfer(
        assetId: 'asset-1',
        fromSiteId: 'site-1',
        toSiteId: 'site-2',
        quantity: 2,
        idempotencyKey: 'request-1',
      ),
    ).thenAnswer((_) async {});

    await queue.sync('user-1');

    verify(
      () => api.transfer(
        assetId: 'asset-1',
        fromSiteId: 'site-1',
        toSiteId: 'site-2',
        quantity: 2,
        idempotencyKey: 'request-1',
      ),
    ).called(1);
    expect(
      (await database.watchMovements('user-1').first).single.status,
      'ENVIADO',
    );
  });

  test('retains API rejection reason for user correction', () async {
    await database.enqueueMovement(
      id: 'local-2',
      ownerId: 'user-1',
      idempotencyKey: 'request-2',
      payload: const {
        'assetId': 'asset-1',
        'fromSiteId': 'site-1',
        'toSiteId': 'site-2',
        'quantity': 8,
      },
    );
    when(
      () => api.transfer(
        assetId: 'asset-1',
        fromSiteId: 'site-1',
        toSiteId: 'site-2',
        quantity: 8,
        idempotencyKey: 'request-2',
      ),
    ).thenThrow(
      const ApiFailure(
        code: 'STOCK_INSUFICIENTE',
        message: 'Stock insuficiente',
        detail: 'Solo hay 3 unidades disponibles.',
      ),
    );

    await queue.sync('user-1');

    final rejected = (await database.watchMovements('user-1').first).single;
    expect(rejected.status, 'RECHAZADO');
    expect(rejected.error, 'Solo hay 3 unidades disponibles.');
  });

  test(
    'leaves movement pending while the network is still unavailable',
    () async {
      await database.enqueueMovement(
        id: 'local-3',
        ownerId: 'user-1',
        idempotencyKey: 'request-3',
        payload: const {
          'assetId': 'asset-1',
          'fromSiteId': 'site-1',
          'toSiteId': 'site-2',
          'quantity': 1,
        },
      );
      when(
        () => api.transfer(
          assetId: 'asset-1',
          fromSiteId: 'site-1',
          toSiteId: 'site-2',
          quantity: 1,
          idempotencyKey: 'request-3',
        ),
      ).thenThrow(ApiFailure.offline);

      await queue.sync('user-1');

      final queued = (await database.watchMovements('user-1').first).single;
      expect(queued.status, 'PENDIENTE');
      expect(queued.attempts, 1);
    },
  );

  test(
    'automatically sends pending movements when connectivity returns',
    () async {
      await database.enqueueMovement(
        id: 'local-reconnect',
        ownerId: 'user-1',
        idempotencyKey: 'request-reconnect',
        payload: const {
          'assetId': 'asset-1',
          'fromSiteId': 'site-1',
          'toSiteId': 'site-2',
          'quantity': 1,
        },
      );
      final connectivity = _ConnectivityMonitor();
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(
            const AppUser(
              id: 'user-1',
              dni: '12345678',
              fullName: 'Operador de prueba',
              role: Role.operador,
              active: true,
              mustChangePassword: false,
            ),
          ),
          localDatabaseProvider.overrideWithValue(database),
          movementsRepositoryProvider.overrideWithValue(api),
          connectivityMonitorProvider.overrideWithValue(connectivity),
        ],
      );
      final transferred = Completer<void>();
      when(
        () => api.transfer(
          assetId: 'asset-1',
          fromSiteId: 'site-1',
          toSiteId: 'site-2',
          quantity: 1,
          idempotencyKey: 'request-reconnect',
        ),
      ).thenAnswer((_) {
        transferred.complete();
        return Future<void>.value();
      });

      container.listen(offlineSyncProvider, (previous, next) {});
      connectivity.changes.add([ConnectivityResult.wifi]);
      await transferred.future.timeout(const Duration(seconds: 1));
      await database
          .watchMovements('user-1')
          .firstWhere((rows) => rows.single.status == 'ENVIADO')
          .timeout(const Duration(seconds: 1));

      verify(
        () => api.transfer(
          assetId: 'asset-1',
          fromSiteId: 'site-1',
          toSiteId: 'site-2',
          quantity: 1,
          idempotencyKey: 'request-reconnect',
        ),
      ).called(1);
      container.dispose();
      await connectivity.changes.close();
    },
  );
}
