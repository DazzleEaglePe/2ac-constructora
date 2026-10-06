import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/session_controller.dart';
import '../../features/assets/domain/asset.dart';
import '../../features/movements/data/movements_repository.dart';
import '../network/api_failure.dart';
import 'local_database.dart';

final offlineMovementQueueProvider = Provider<OfflineMovementQueue>(
  (ref) => OfflineMovementQueue(
    ref.watch(localDatabaseProvider),
    ref.watch(movementsRepositoryProvider),
  ),
);

final pendingMovementsProvider = StreamProvider.autoDispose
    .family<List<PendingMovement>, String>((ref, ownerId) {
      return ref.watch(localDatabaseProvider).watchMovements(ownerId);
    });

abstract interface class ConnectivityMonitor {
  Future<List<ConnectivityResult>> checkConnectivity();

  Stream<List<ConnectivityResult>> get onConnectivityChanged;
}

class PluginConnectivityMonitor implements ConnectivityMonitor {
  PluginConnectivityMonitor([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() =>
      _connectivity.checkConnectivity();

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}

final connectivityMonitorProvider = Provider<ConnectivityMonitor>(
  (ref) => PluginConnectivityMonitor(),
);

final connectivityStatusProvider = StreamProvider<List<ConnectivityResult>>((
  ref,
) async* {
  final connectivity = ref.watch(connectivityMonitorProvider);
  yield await connectivity.checkConnectivity();
  yield* connectivity.onConnectivityChanged;
});

final offlineCacheFetchedAtProvider = StreamProvider<DateTime?>((ref) {
  return ref.watch(localDatabaseProvider).watchLatestCacheFetchedAt();
});

Asset applyPendingMovementsToAsset(
  Asset asset,
  List<PendingMovement> movements,
) {
  final distribution = <String, AssetDistribution>{
    for (final row in asset.distribution) row.siteId: row,
  };
  for (final movement in movements.where(
    (item) => item.status == 'PENDIENTE',
  )) {
    final payload = jsonDecode(movement.payload) as Map<String, dynamic>;
    if (payload['assetId'] != asset.id) continue;
    final fromSiteId = payload['fromSiteId'] as String;
    final toSiteId = payload['toSiteId'] as String;
    final quantity = payload['quantity'] as int;
    final source = distribution[fromSiteId];
    final target = distribution[toSiteId];
    if (source != null) {
      distribution[fromSiteId] = AssetDistribution(
        siteId: source.siteId,
        siteName: source.siteName,
        siteType: source.siteType,
        quantity: source.quantity - quantity,
      );
    }
    distribution[toSiteId] = AssetDistribution(
      siteId: toSiteId,
      siteName: target?.siteName ?? toSiteId,
      siteType: target?.siteType ?? 'OBRA',
      quantity: (target?.quantity ?? 0) + quantity,
    );
  }
  return Asset(
    id: asset.id,
    code: asset.code,
    type: asset.type,
    name: asset.name,
    description: asset.description,
    status: asset.status,
    totalStock: asset.totalStock,
    distribution: distribution.values.toList(growable: false),
    notesCount: asset.notesCount,
  );
}

/// Starts a single sequential worker for the signed-in user's pending queue.
final offlineSyncProvider = Provider<void>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return;
  final queue = ref.watch(offlineMovementQueueProvider);
  final connectivity = ref.watch(connectivityMonitorProvider);
  Future<void> syncIfOnline(List<ConnectivityResult> results) async {
    if (results.contains(ConnectivityResult.none)) return;
    await queue.sync(user.id);
  }

  final subscription = connectivity.onConnectivityChanged.listen(syncIfOnline);
  unawaited(connectivity.checkConnectivity().then(syncIfOnline));
  ref.onDispose(subscription.cancel);
});

class OfflineMovementQueue {
  OfflineMovementQueue(this._database, this._movements);

  final LocalDatabase _database;
  final MovementsRepository _movements;
  bool _syncing = false;

  Future<void> enqueue({
    required String ownerId,
    required Map<String, Object?> payload,
    String? id,
    String? idempotencyKey,
  }) => _database.enqueueMovement(
    id: id ?? _uuidV4(),
    ownerId: ownerId,
    idempotencyKey: idempotencyKey ?? _uuidV4(),
    payload: payload,
  );

  Future<void> correctRejected(String id, Map<String, Object?> payload) =>
      _database.updateMovement(
        id: id,
        payload: jsonEncode(payload),
        idempotencyKey: _uuidV4(),
      );

  Future<void> sync(String ownerId) async {
    if (_syncing) return;
    _syncing = true;
    try {
      for (final item in await _database.pendingForSync(ownerId)) {
        await _database.setMovementStatus(
          item.id,
          status: 'PENDIENTE',
          incrementAttempts: true,
        );
        try {
          final payload = jsonDecode(item.payload) as Map<String, dynamic>;
          await _movements.transfer(
            assetId: payload['assetId'] as String,
            fromSiteId: payload['fromSiteId'] as String,
            toSiteId: payload['toSiteId'] as String,
            quantity: payload['quantity'] as int,
            note: payload['note'] as String?,
            observationType: payload['observationType'] as String?,
            observationDescription:
                payload['observationDescription'] as String?,
            idempotencyKey: item.idempotencyKey,
          );
          await _database.setMovementStatus(item.id, status: 'ENVIADO');
        } on ApiFailure catch (failure) {
          if (failure.code == ApiFailure.offline.code ||
              (failure.status != null && failure.status! >= 500) ||
              failure.status == 401) {
            break;
          }
          await _database.setMovementStatus(
            item.id,
            status: 'RECHAZADO',
            error: failure.detail ?? failure.message,
          );
        }
      }
    } finally {
      _syncing = false;
    }
  }
}

String _uuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
