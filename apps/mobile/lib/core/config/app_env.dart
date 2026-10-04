/// Configuración por entorno inyectada con `--dart-define-from-file=env/<entorno>.json`.
///
/// En el emulador de Android, `localhost` del equipo es `10.0.2.2`.
abstract final class AppEnv {
  static const name = String.fromEnvironment('ENV', defaultValue: 'dev');
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3100/api/v1',
  );
  static const wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'http://localhost:3100/realtime',
  );
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  static bool get isDev => name == 'dev';
  static bool get isProd => name == 'prod';

  /// URL de salud de la API (fuera del prefijo `/api/v1`).
  static Uri get healthUrl =>
      Uri.parse(apiBaseUrl).replace(path: '/health/ready');
}
