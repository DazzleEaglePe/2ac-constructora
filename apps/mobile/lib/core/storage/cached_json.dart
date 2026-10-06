import 'package:dio/dio.dart';

import '../network/api_failure.dart';
import 'local_database.dart';

/// Reads a successful GET from the API and keeps its JSON for offline use.
/// Cached values are used only for transport failures, never for API errors.
Future<Object?> getCachedJson({
  required Dio dio,
  required LocalDatabase? database,
  required String key,
  required String path,
  Map<String, Object?>? queryParameters,
}) async {
  try {
    final response = await dio.get<Object?>(
      path,
      queryParameters: queryParameters,
    );
    final body = response.data;
    if (database != null && body != null) {
      await database.putCache(key, body);
    }
    return body;
  } on DioException catch (error) {
    final failure = ApiFailure.fromDio(error);
    if (failure.code != ApiFailure.offline.code || database == null) {
      throw failure;
    }
    final cached = await database.getCache(key);
    if (cached != null) return cached;
    throw failure;
  }
}
