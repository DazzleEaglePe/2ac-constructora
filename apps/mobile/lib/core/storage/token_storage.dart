import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda el refresh token en Keychain / Keystore (docs/07 §5).
/// El access token vive solo en memoria ([AccessTokenHolder]).
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _refreshKey = 'a2c.refresh_token';

  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshKey, value: token);
  Future<void> clear() => _storage.delete(key: _refreshKey);
}

/// Access token en memoria, leído por el interceptor HTTP.
class AccessTokenHolder {
  String? token;
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
final accessTokenHolderProvider = Provider<AccessTokenHolder>(
  (ref) => AccessTokenHolder(),
);
