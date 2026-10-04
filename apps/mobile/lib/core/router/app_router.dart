import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dev/component_catalog_screen.dart';
import '../../features/dev/placeholder_home_screen.dart';
import '../config/app_env.dart';

/// Rutas de la app (docs/08 §1). En S1 se agregan splash, onboarding, ingreso y guardas de sesión.
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppEnv.isDev ? '/dev/catalog' : '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const PlaceholderHomeScreen()),
      if (AppEnv.isDev)
        GoRoute(
          path: '/dev/catalog',
          builder: (_, _) => const ComponentCatalogScreen(),
        ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
