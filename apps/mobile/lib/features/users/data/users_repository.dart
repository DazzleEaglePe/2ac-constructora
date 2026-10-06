import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/domain/app_user.dart';

/// Endpoints de usuarios, solo administradores (docs/06 §3).
class UsersRepository {
  UsersRepository(this._dio);

  final Dio _dio;

  Future<List<AppUser>> list({String? query}) => guardApi(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/users',
      queryParameters: {
        'limit': 100,
        if (query != null && query.isNotEmpty) 'q': query,
      },
    );
    return (res.data!['data'] as List<dynamic>)
        .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
        .toList();
  });

  Future<AppUser> create({
    required String dni,
    required String fullName,
    required Role role,
    required String temporaryPassword,
  }) => guardApi(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/users',
      data: {
        'dni': dni,
        'fullName': fullName,
        'role': role.apiValue,
        'temporaryPassword': temporaryPassword,
      },
    );
    return AppUser.fromJson(res.data!);
  });

  Future<AppUser> update(String id, {String? fullName, Role? role}) => guardApi(
    () async {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/users/$id',
        data: {'fullName': ?fullName, if (role != null) 'role': role.apiValue},
      );
      return AppUser.fromJson(res.data!);
    },
  );

  Future<AppUser> setActive(String id, bool active) => guardApi(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/users/$id/${active ? 'activate' : 'deactivate'}',
    );
    return AppUser.fromJson(res.data!);
  });

  Future<String> resetPassword(String id) => guardApi(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/users/$id/reset-password',
    );
    return res.data!['temporaryPassword'] as String;
  });
}

final usersRepositoryProvider = Provider<UsersRepository>(
  (ref) => UsersRepository(ref.watch(dioProvider)),
);

final usersListProvider = FutureProvider.autoDispose<List<AppUser>>(
  (ref) => ref.watch(usersRepositoryProvider).list(),
);
