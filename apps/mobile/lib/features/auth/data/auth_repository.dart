import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/network/dio_client.dart';
import '../domain/app_user.dart';

class LoginResult {
  const LoginResult(this.tokens, this.user);

  final TokenPair tokens;
  final AppUser user;
}

/// Endpoints de autenticación (docs/06 §2).
class AuthRepository {
  AuthRepository({required Dio publicDio, required Dio authedDio})
    : _public = publicDio,
      _authed = authedDio;

  final Dio _public;
  final Dio _authed;

  Future<LoginResult> login({
    required String dni,
    required String password,
    String? deviceName,
  }) => guardApi(() async {
    final res = await _public.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'dni': dni, 'password': password, 'deviceName': ?deviceName},
    );
    final body = res.data!;
    return LoginResult(
      TokenPair.fromJson(body),
      AppUser.fromJson(body['user'] as Map<String, dynamic>),
    );
  });

  Future<TokenPair> refresh(String refreshToken) => guardApi(() async {
    final res = await _public.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return TokenPair.fromJson(res.data!);
  });

  Future<void> logout(String refreshToken) => guardApi(() async {
    await _public.post<void>(
      '/auth/logout',
      data: {'refreshToken': refreshToken},
    );
  });

  Future<AppUser> me() => guardApi(() async {
    final res = await _authed.get<Map<String, dynamic>>('/auth/me');
    return AppUser.fromJson(res.data!);
  });

  Future<TokenPair> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => guardApi(() async {
    final res = await _authed.post<Map<String, dynamic>>(
      '/auth/change-password',
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
    return TokenPair.fromJson(res.data!);
  });
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    publicDio: ref.watch(authDioProvider),
    authedDio: ref.watch(dioProvider),
  ),
);
