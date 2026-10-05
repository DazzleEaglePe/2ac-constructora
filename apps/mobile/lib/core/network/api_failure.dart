import 'package:dio/dio.dart';

/// Error de la API en formato `application/problem+json` (docs/06 §1),
/// o de red cuando no hay conexión.
class ApiFailure implements Exception {
  const ApiFailure({
    required this.code,
    required this.message,
    this.status,
    this.detail,
    this.extra = const {},
  });

  final String code;
  final String message;
  final int? status;
  final String? detail;
  final Map<String, dynamic> extra;

  static const offline = ApiFailure(
    code: 'SIN_CONEXION',
    message: 'Sin conexión. Revisa tu señal e inténtalo de nuevo.',
  );

  factory ApiFailure.fromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['code'] is String) {
      return ApiFailure(
        code: data['code'] as String,
        message: (data['title'] as String?) ?? 'Ocurrió un error',
        status: e.response?.statusCode,
        detail: data['detail'] as String?,
        extra: data,
      );
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return offline;
    }
    return ApiFailure(
      code: 'ERROR_INTERNO',
      message: 'Ocurrió un error inesperado. Inténtalo de nuevo.',
      status: e.response?.statusCode,
    );
  }

  @override
  String toString() => 'ApiFailure($code, $message)';
}

/// Ejecuta una llamada y convierte los errores de Dio en [ApiFailure].
Future<T> guardApi<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on DioException catch (e) {
    throw ApiFailure.fromDio(e);
  }
}
