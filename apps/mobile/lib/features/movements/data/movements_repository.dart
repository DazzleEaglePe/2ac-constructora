import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/network/dio_client.dart';
import '../domain/movement.dart';

class MovementsRepository {
  MovementsRepository(this._dio);
  final Dio _dio;

  Future<List<Movement>> history(String assetId) => guardApi(() async {
    final response = await _dio.get<List<dynamic>>(
      '/movements',
      queryParameters: {'assetId': assetId},
    );
    return (response.data ?? const [])
        .map((row) => Movement.fromJson(row as Map<String, dynamic>))
        .toList(growable: false);
  });

  Future<void> transfer({
    required String assetId,
    required String fromSiteId,
    required String toSiteId,
    required int quantity,
    String? note,
    String? observationType,
    String? observationDescription,
  }) => guardApi(() async {
    await _dio.post<Map<String, dynamic>>(
      '/movements',
      options: Options(headers: {'Idempotency-Key': _uuidV4()}),
      data: {
        'assetId': assetId,
        'fromSiteId': fromSiteId,
        'toSiteId': toSiteId,
        'quantity': quantity,
        if (note?.trim().isNotEmpty ?? false) 'note': note!.trim(),
        if (observationType != null && observationDescription != null)
          'observation': {
            'type': observationType,
            'description': observationDescription.trim(),
          },
      },
    );
  });

  Future<void> resolveObservation(String id, String resolution) =>
      guardApi(() async {
        await _dio.post<Map<String, dynamic>>(
          '/observations/$id/resolve',
          data: {'resolution': resolution.trim()},
        );
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

final movementsRepositoryProvider = Provider<MovementsRepository>(
  (ref) => MovementsRepository(ref.watch(dioProvider)),
);

final assetMovementHistoryProvider = FutureProvider.autoDispose
    .family<List<Movement>, String>(
      (ref, assetId) => ref.watch(movementsRepositoryProvider).history(assetId),
    );
