import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/network/dio_client.dart';
import '../domain/audit_log.dart';

class AuditRepository {
  AuditRepository(this._dio);
  final Dio _dio;

  Future<AuditLogPage> list({String? action, String? cursor}) =>
      guardApi(() async {
        final query = <String, Object?>{'action': action, 'cursor': cursor}
          ..removeWhere((_, value) => value == null || value == '');
        final response = await _dio.get<Map<String, dynamic>>(
          '/audit-logs',
          queryParameters: query,
        );
        return AuditLogPage.fromJson(response.data!);
      });
}

final auditRepositoryProvider = Provider<AuditRepository>(
  (ref) => AuditRepository(ref.watch(dioProvider)),
);
