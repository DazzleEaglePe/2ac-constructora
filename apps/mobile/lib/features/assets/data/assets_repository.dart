import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/cached_json.dart';
import '../../../core/storage/local_database.dart';
import '../../../core/storage/offline_movements.dart';
import '../../auth/application/session_controller.dart';
import '../domain/asset.dart';

class AssetsRepository {
  AssetsRepository(this._dio, [this._database]);

  final Dio _dio;
  final LocalDatabase? _database;

  Future<List<Asset>> list({
    String? q,
    String? type,
    String? status,
  }) => guardApi(() async {
    final query = <String, dynamic>{};
    if (q?.trim().isNotEmpty ?? false) query['q'] = q!.trim();
    if (type != null) query['type'] = type;
    if (status != null) query['status'] = status;
    final body = await getCachedJson(
      dio: _dio,
      database: _database,
      key:
          'assets:list:${query.entries.toList()..sort((a, b) => a.key.compareTo(b.key))}',
      path: '/assets',
      queryParameters: query,
    );
    return ((body as List<dynamic>?) ?? const [])
        .map((json) => Asset.fromJson(json as Map<String, dynamic>))
        .toList(growable: false);
  });

  Future<AssetPage> search({
    String? q,
    String? type,
    String? status,
    String? siteId,
    String? cursor,
    int limit = 50,
  }) => guardApi(() async {
    final query = <String, Object?>{
      'q': q,
      'type': type,
      'status': status,
      'siteId': siteId,
      'cursor': cursor,
      'limit': limit,
    }..removeWhere((_, value) => value == null || value == '');
    final body = await getCachedJson(
      dio: _dio,
      database: _database,
      key:
          'assets:search:${query.entries.toList()..sort((a, b) => a.key.compareTo(b.key))}',
      path: '/assets/search',
      queryParameters: query,
    );
    return AssetPage.fromJson(body! as Map<String, dynamic>);
  });

  Future<String> nextCode(String type) => guardApi(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/assets/next-code',
      queryParameters: {'type': type},
    );
    return response.data!['code'] as String;
  });

  Future<Asset> get(String id) => guardApi(() async {
    final body = await getCachedJson(
      dio: _dio,
      database: _database,
      key: 'assets:detail:$id',
      path: '/assets/$id',
    );
    return Asset.fromJson(body! as Map<String, dynamic>);
  });

  Future<List<AssetNote>> notes(String id) => guardApi(() async {
    final response = await _dio.get<List<dynamic>>('/assets/$id/notes');
    return (response.data ?? const [])
        .map((json) => AssetNote.fromJson(json as Map<String, dynamic>))
        .toList(growable: false);
  });

  Future<void> addNote(String id, String body) => guardApi(() async {
    await _dio.post<Map<String, dynamic>>(
      '/assets/$id/notes',
      data: {'body': body},
    );
  });

  Future<Asset> update(
    String id, {
    required String name,
    String? description,
  }) => guardApi(() async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/assets/$id',
      data: {'name': name, 'description': description},
    );
    return Asset.fromJson(response.data!);
  });

  Future<Asset> changeStatus(
    String id, {
    required String status,
    String? reason,
  }) => guardApi(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/assets/$id/status',
      data: {'status': status, 'reason': reason},
    );
    return Asset.fromJson(response.data!);
  });

  Future<Asset> create({
    required String type,
    required String name,
    String? description,
    required int initialQuantity,
    required String initialSiteId,
  }) => guardApi(() async {
    final key = _uuidV4();
    final response = await _dio.post<Map<String, dynamic>>(
      '/assets',
      options: Options(headers: {'Idempotency-Key': key}),
      data: {
        'type': type,
        'name': name,
        'description': description,
        'status': 'OPERATIVO',
        'initialQuantity': initialQuantity,
        'initialSiteId': initialSiteId,
      },
    );
    return Asset.fromJson(response.data!);
  });
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

final assetsRepositoryProvider = Provider<AssetsRepository>(
  (ref) => AssetsRepository(
    ref.watch(dioProvider),
    ref.watch(localDatabaseProvider),
  ),
);

final assetsListProvider = FutureProvider.autoDispose<List<Asset>>(
  (ref) => ref.watch(assetsRepositoryProvider).list(),
);

class AssetSearchQueryController extends Notifier<AssetSearchQuery> {
  @override
  AssetSearchQuery build() => const AssetSearchQuery();

  void update({
    required String q,
    required String? type,
    required String? status,
  }) {
    state = AssetSearchQuery(q: q, type: type, status: status);
  }
}

final assetSearchQueryProvider =
    NotifierProvider<AssetSearchQueryController, AssetSearchQuery>(
      AssetSearchQueryController.new,
    );

class InventoryAssetsController extends AsyncNotifier<AssetPage> {
  @override
  Future<AssetPage> build() {
    final query = ref.watch(assetSearchQueryProvider);
    return ref
        .read(assetsRepositoryProvider)
        .search(
          q: query.q.isEmpty ? null : query.q,
          type: query.type,
          status: query.status,
        );
  }

  Future<void> loadMore() async {
    final page = state.asData?.value;
    final query = ref.read(assetSearchQueryProvider);
    final cursor = page?.nextCursor;
    if (page == null || cursor == null) return;
    final next = await ref
        .read(assetsRepositoryProvider)
        .search(
          q: query.q.isEmpty ? null : query.q,
          type: query.type,
          status: query.status,
          cursor: cursor,
        );
    if (ref.read(assetSearchQueryProvider) != query ||
        state.asData?.value.nextCursor != cursor) {
      return;
    }
    state = AsyncData(
      AssetPage(
        assets: [...page.assets, ...next.assets],
        nextCursor: next.nextCursor,
      ),
    );
  }
}

final inventoryAssetsProvider =
    AsyncNotifierProvider.autoDispose<InventoryAssetsController, AssetPage>(
      InventoryAssetsController.new,
    );

void invalidateAssetCatalog(Ref ref) {
  ref
    ..invalidate(assetsListProvider)
    ..invalidate(inventoryAssetsProvider);
}

void invalidateWidgetAssetCatalog(WidgetRef ref) {
  ref
    ..invalidate(assetsListProvider)
    ..invalidate(inventoryAssetsProvider);
}

final nextAssetCodeProvider = FutureProvider.autoDispose.family<String, String>(
  (ref, type) => ref.watch(assetsRepositoryProvider).nextCode(type),
);

final assetDetailProvider = FutureProvider.autoDispose.family<Asset, String>((
  ref,
  id,
) async {
  final asset = await ref.watch(assetsRepositoryProvider).get(id);
  final user = ref.watch(currentUserProvider);
  if (user == null) return asset;
  final pending = await ref.watch(pendingMovementsProvider(user.id).future);
  return applyPendingMovementsToAsset(asset, pending);
});

final assetNotesProvider = FutureProvider.autoDispose
    .family<List<AssetNote>, String>(
      (ref, id) => ref.watch(assetsRepositoryProvider).notes(id),
    );
