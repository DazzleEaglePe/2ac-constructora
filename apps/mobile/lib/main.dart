import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'core/config/app_env.dart';
import 'core/storage/preferences.dart';

/// Punto de entrada único. El entorno se define con
/// `flutter run --dart-define-from-file=env/dev.json` (docs/11 §6).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  final prefs = await SharedPreferences.getInstance();
  await SentryFlutter.init(
    (options) {
      options.dsn = AppEnv.sentryDsn;
      options.environment = AppEnv.name;
      options.sendDefaultPii = false;
    },
    appRunner: () => runApp(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const A2CApp(),
      ),
    ),
  );
}
