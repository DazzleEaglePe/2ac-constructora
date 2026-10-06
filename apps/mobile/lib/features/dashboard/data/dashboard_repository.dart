import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/cached_json.dart';
import '../../../core/storage/local_database.dart';
import '../domain/dashboard_data.dart';

class DashboardRepository {
  DashboardRepository(this._dio, [this._database]);
  final Dio _dio;
  final LocalDatabase? _database;

  Future<DashboardData> get({DateTime? since}) => guardApi(() async {
    final body = await getCachedJson(
      dio: _dio,
      database: _database,
      key: since == null
          ? 'dashboard:full'
          : 'dashboard:${since.toUtc().toIso8601String()}',
      path: '/dashboard',
      queryParameters: since == null
          ? null
          : {'since': since.toUtc().toIso8601String()},
    );
    return DashboardData.fromJson(body! as Map<String, dynamic>);
  });
}

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(
    ref.watch(dioProvider),
    ref.watch(localDatabaseProvider),
  ),
);

final dashboardProvider = FutureProvider.autoDispose<DashboardData>(
  (ref) => ref.watch(dashboardRepositoryProvider).get(),
);
