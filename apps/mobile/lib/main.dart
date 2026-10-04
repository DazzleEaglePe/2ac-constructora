import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// Punto de entrada único. El entorno se define con
/// `flutter run --dart-define-from-file=env/dev.json` (docs/11 §6).
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: A2CApp()));
}
