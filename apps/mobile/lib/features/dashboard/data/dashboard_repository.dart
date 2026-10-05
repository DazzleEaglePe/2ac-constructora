import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/network/dio_client.dart';
import '../domain/dashboard_data.dart';

class DashboardRepository {
  DashboardRepository(this._dio);
  final Dio _dio;

  Future<DashboardData> get({DateTime? since}) => guardApi(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/dashboard',
      queryParameters: since == null
          ? null
          : {'since': since.toUtc().toIso8601String()},
    );
    return DashboardData.fromJson(response.data!);
  });
}

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(dioProvider)),
);

final dashboardProvider = FutureProvider.autoDispose<DashboardData>(
  (ref) => ref.watch(dashboardRepositoryProvider).get(),
);
