import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/session_controller.dart';
import '../config/app_env.dart';
import '../storage/token_storage.dart';

BaseOptions _baseOptions() => BaseOptions(
  baseUrl: AppEnv.apiBaseUrl,
  connectTimeout: const Duration(seconds: 8),
  receiveTimeout: const Duration(seconds: 15),
  headers: {'Accept': 'application/json'},
);

/// Cliente sin sesión para `/auth/login`, `/auth/refresh` y `/auth/logout`.
final authDioProvider = Provider<Dio>((ref) {
  final dio = Dio(_baseOptions());
  ref.onDispose(dio.close);
  return dio;
});

/// Cliente autenticado: agrega el access token y, ante un 401, renueva la
/// sesión una sola vez y reintenta (docs/07 §3).
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(_baseOptions());
  final holder = ref.watch(accessTokenHolderProvider);

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = holder.token;
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (error, handler) async {
        final request = error.requestOptions;
        final alreadyRetried = request.extra['a2cRetried'] == true;
        if (error.response?.statusCode != 401 || alreadyRetried) {
          return handler.next(error);
        }

        final responseBody = error.response?.data;
        final errorCode = responseBody is Map<String, dynamic>
            ? responseBody['code']
            : null;
        if (errorCode != 'NO_AUTENTICADO') return handler.next(error);

        final renewed = await ref
            .read(sessionProvider.notifier)
            .renewAccessToken();
        if (!renewed) return handler.next(error);
        try {
          request.extra['a2cRetried'] = true;
          request.headers['Authorization'] = 'Bearer ${holder.token}';
          handler.resolve(await dio.fetch<dynamic>(request));
        } on DioException catch (e) {
          handler.next(e);
        }
      },
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});

/// Estado de la API (`/health/ready`), usado por el catálogo de desarrollo.
final apiHealthProvider = FutureProvider.autoDispose<bool>((ref) async {
  final dio = ref.watch(authDioProvider);
  try {
    final res = await dio.getUri<Map<String, dynamic>>(AppEnv.healthUrl);
    return res.data?['status'] == 'ok';
  } on DioException {
    return false;
  }
});
