import '../../features/auth/domain/session_state.dart';

/// Rutas accesibles sin sesión.
const publicRoutes = {'/onboarding', '/login'};

/// Guardas de navegación (docs/08 §2). Función pura para poder probarla.
String? appRedirect({
  required SessionState session,
  required bool onboardingSeen,
  required String location,
}) {
  if (location == '/splash') return null;
  if (location.startsWith('/dev/')) return null;

  switch (session) {
    case SessionUnknown():
      return '/splash';
    case SessionSignedOut():
      if (publicRoutes.contains(location)) return null;
      return onboardingSeen ? '/login' : '/onboarding';
    case SessionSignedIn(:final user):
      if (user.mustChangePassword) {
        return location == '/change-password' ? null : '/change-password';
      }
      if (publicRoutes.contains(location) || location == '/change-password') {
        return '/';
      }
      if (location.startsWith('/users') && !user.isAdmin) return '/';
      if (location.startsWith('/audit') && !user.isAdmin) return '/';
      return null;
  }
}

/// Destino al terminar el splash.
String routeAfterSplash({
  required SessionState session,
  required bool onboardingSeen,
}) => switch (session) {
  SessionSignedIn() => '/',
  _ => onboardingSeen ? '/login' : '/onboarding',
};
