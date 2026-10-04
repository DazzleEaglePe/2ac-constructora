import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_env.dart';

/// Cliente HTTP compartido. En S1 se agregan los interceptores de sesión
/// (refresh de token) y de `Idempotency-Key` (docs/04 §3).
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppEnv.apiBaseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});

/// Estado de la API (`/health/ready`), usado por el catálogo de desarrollo.
final apiHealthProvider = FutureProvider.autoDispose<bool>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.getUri<Map<String, dynamic>>(AppEnv.healthUrl);
    return res.data?['status'] == 'ok';
  } on DioException {
    return false;
  }
});
