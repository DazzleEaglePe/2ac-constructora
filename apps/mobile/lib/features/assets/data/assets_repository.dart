import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/network/dio_client.dart';
import '../domain/asset.dart';

class AssetsRepository {
  AssetsRepository(this._dio);

  final Dio _dio;

  Future<List<Asset>> list({String? q, String? type, String? status}) =>
      guardApi(() async {
        final query = <String, dynamic>{};
        if (q?.trim().isNotEmpty ?? false) query['q'] = q!.trim();
        if (type != null) query['type'] = type;
        if (status != null) query['status'] = status;
        final response = await _dio.get<List<dynamic>>(
          '/assets',
          queryParameters: query,
        );
        return (response.data ?? const [])
            .map((json) => Asset.fromJson(json as Map<String, dynamic>))
            .toList(growable: false);
      });

  Future<String> nextCode(String type) => guardApi(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/assets/next-code',
      queryParameters: {'type': type},
    );
    return response.data!['code'] as String;
  });

  Future<Asset> get(String id) => guardApi(() async {
    final response = await _dio.get<Map<String, dynamic>>('/assets/$id');
    return Asset.fromJson(response.data!);
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
  (ref) => AssetsRepository(ref.watch(dioProvider)),
);

final assetsListProvider = FutureProvider.autoDispose<List<Asset>>(
  (ref) => ref.watch(assetsRepositoryProvider).list(),
);

final nextAssetCodeProvider = FutureProvider.autoDispose.family<String, String>(
  (ref, type) => ref.watch(assetsRepositoryProvider).nextCode(type),
);

final assetDetailProvider = FutureProvider.autoDispose.family<Asset, String>(
  (ref, id) => ref.watch(assetsRepositoryProvider).get(id),
);

final assetNotesProvider = FutureProvider.autoDispose
    .family<List<AssetNote>, String>(
      (ref, id) => ref.watch(assetsRepositoryProvider).notes(id),
    );
