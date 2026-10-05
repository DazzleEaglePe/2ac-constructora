import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/session_controller.dart';
import '../../features/auth/presentation/change_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dev/component_catalog_screen.dart';
import '../../features/shell/dashboard_screen.dart';
import '../../features/shell/home_shell.dart';
import '../../features/shell/inventory_screen.dart';
import '../../features/sites/domain/site.dart';
import '../../features/sites/presentation/new_site_screen.dart';
import '../../features/sites/presentation/site_detail_screen.dart';
import '../../features/users/presentation/users_screen.dart';
import '../../features/welcome/onboarding_screen.dart';
import '../../features/welcome/splash_screen.dart';
import '../config/app_env.dart';
import '../storage/preferences.dart';
import 'redirect.dart';

/// Rutas de la app (docs/08 §1) con guardas de sesión ([appRedirect]).
final appRouterProvider = Provider<GoRouter>((ref) {
  // Re-evalúa las guardas cuando cambian la sesión o el onboarding.
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(sessionProvider, (_, _) => refresh.value++)
    ..listen(onboardingSeenProvider, (_, _) => refresh.value++)
    ..onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) => appRedirect(
      session: ref.read(sessionProvider),
      onboardingSeen: ref.read(onboardingSeenProvider),
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/change-password',
        builder: (_, _) => const ChangePasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const DashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'sites/new',
                    builder: (_, _) => const NewSiteScreen(),
                  ),
                  GoRoute(
                    path: 'sites/:siteId',
                    builder: (_, state) => SiteDetailScreen(
                      siteId: state.pathParameters['siteId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (_, state) =>
                            NewSiteScreen(initialSite: state.extra as Site?),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inventory',
                builder: (_, _) => const InventoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/users', builder: (_, _) => const UsersScreen()),
            ],
          ),
        ],
      ),
      if (AppEnv.isDev || kDebugMode)
        GoRoute(
          path: '/dev/catalog',
          builder: (_, _) => const ComponentCatalogScreen(),
        ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
