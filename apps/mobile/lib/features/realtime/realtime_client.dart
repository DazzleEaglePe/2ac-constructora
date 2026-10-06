import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

typedef RealtimeTokenRefresh = Future<String?> Function();
typedef RealtimeEventHandler = void Function(String event, dynamic payload);

class RealtimeClient {
  RealtimeClient({
    required String url,
    required String accessToken,
    required this._refreshToken,
    required this._onEvent,
    required this._onSessionRevoked,
  }) {
    _socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': accessToken})
          .enableReconnection()
          .setReconnectionDelay(500)
          .setReconnectionDelayMax(30000)
          .setRandomizationFactor(0.5)
          .build(),
    );
    _socket.onConnect((_) => _setConnected(true));
    _socket.onDisconnect((_) => _setConnected(false));
    _socket.onConnectError((error) {
      if ('$error'.contains('NO_AUTENTICADO')) _refreshAuth();
    });
    for (final event in const [
      'movement.created',
      'stock.updated',
      'site.updated',
      'asset.updated',
    ]) {
      _socket.on(event, (payload) => _onEvent(event, payload));
    }
    _socket.on('session.revoked', (_) => _onSessionRevoked());
    scheduleMicrotask(() => _setConnected(_socket.connected));
  }

  final RealtimeTokenRefresh _refreshToken;
  final RealtimeEventHandler _onEvent;
  final void Function() _onSessionRevoked;
  final StreamController<bool> _connection = StreamController<bool>.broadcast();
  late final io.Socket _socket;
  bool _lastConnection = false;
  bool _disposed = false;

  Stream<bool> get connection => _connection.stream;

  void _setConnected(bool connected) {
    if (_disposed || connected == _lastConnection) return;
    _lastConnection = connected;
    _connection.add(connected);
  }

  Future<void> _refreshAuth() async {
    final token = await _refreshToken();
    if (_disposed || token == null) return;
    _socket.auth = {'token': token};
  }

  void dispose() {
    _disposed = true;
    _socket.dispose();
    unawaited(_connection.close());
  }
}
