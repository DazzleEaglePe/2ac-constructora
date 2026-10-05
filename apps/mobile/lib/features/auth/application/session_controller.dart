import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';
import '../domain/session_state.dart';

/// Ciclo de vida de la sesión: restaurar al abrir la app, ingresar, renovar,
/// cambiar la contraseña temporal y salir (RF-AUT-01…05).
class SessionController extends Notifier<SessionState> {
  Future<bool>? _renewing;

  AuthRepository get _repo => ref.read(authRepositoryProvider);
  TokenStorage get _storage => ref.read(tokenStorageProvider);
  AccessTokenHolder get _holder => ref.read(accessTokenHolderProvider);

  @override
  SessionState build() => const SessionUnknown();

  /// RF-AUT-02: al abrir la app, recupera la sesión con el refresh token guardado.
  Future<void> restore() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null) {
      state = const SessionSignedOut();
      return;
    }
    try {
      await _applyTokens(await _repo.refresh(refreshToken));
      state = SessionSignedIn(await _repo.me());
    } on ApiFailure catch (e) {
      if (e.code == ApiFailure.offline.code) {
        // Sin red: en S6 se entra con la caché local. Por ahora se pide ingresar.
        state = const SessionSignedOut(
          reason: 'Sin conexión para verificar tu sesión.',
        );
      } else {
        await _clear();
        state = const SessionSignedOut();
      }
    }
  }

  Future<void> login({
    required String dni,
    required String password,
    String? deviceName,
  }) async {
    final result = await _repo.login(
      dni: dni,
      password: password,
      deviceName: deviceName,
    );
    await _applyTokens(result.tokens);
    state = SessionSignedIn(result.user);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final tokens = await _repo.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    await _applyTokens(tokens);
    final current = state;
    if (current is SessionSignedIn) {
      state = SessionSignedIn(current.user.copyWith(mustChangePassword: false));
    }
  }

  Future<void> logout() async {
    final refreshToken = await _storage.readRefreshToken();
    await _clear();
    state = const SessionSignedOut();
    // Revocar en el servidor es "mejor esfuerzo": salir nunca debe fallar por la red.
    if (refreshToken != null) {
      unawaited(() async {
        try {
          await _repo.logout(refreshToken);
        } catch (_) {}
      }());
    }
  }

  /// Llamado por el interceptor HTTP ante un 401. Varias llamadas simultáneas
  /// comparten la misma renovación.
  Future<bool> renewAccessToken() =>
      _renewing ??= _renew().whenComplete(() => _renewing = null);

  Future<bool> _renew() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null) return false;
    try {
      await _applyTokens(await _repo.refresh(refreshToken));
      return true;
    } on ApiFailure catch (e) {
      if (e.code == ApiFailure.offline.code) return false;
      await _clear();
      state = const SessionSignedOut(
        reason: 'Tu sesión venció. Ingresa de nuevo.',
      );
      return false;
    }
  }

  Future<void> _applyTokens(TokenPair tokens) async {
    _holder.token = tokens.accessToken;
    await _storage.saveRefreshToken(tokens.refreshToken);
  }

  Future<void> _clear() async {
    _holder.token = null;
    await _storage.clear();
  }
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

/// Usuario autenticado actual (o null).
final currentUserProvider = Provider<AppUser?>((ref) {
  final session = ref.watch(sessionProvider);
  return session is SessionSignedIn ? session.user : null;
});
