import 'package:a2c_inventario/core/router/redirect.dart';
import 'package:a2c_inventario/features/auth/domain/app_user.dart';
import 'package:a2c_inventario/features/auth/domain/session_state.dart';
import 'package:flutter_test/flutter_test.dart';

AppUser _user({Role role = Role.operador, bool mustChange = false}) => AppUser(
  id: 'u1',
  dni: '30456789',
  fullName: 'Carlos Pérez',
  role: role,
  active: true,
  mustChangePassword: mustChange,
);

void main() {
  group('appRedirect (docs/08 §2)', () {
    test('sin sesión verificada todo va al splash', () {
      expect(
        appRedirect(
          session: const SessionUnknown(),
          onboardingSeen: true,
          location: '/',
        ),
        '/splash',
      );
      expect(
        appRedirect(
          session: const SessionUnknown(),
          onboardingSeen: true,
          location: '/splash',
        ),
        isNull,
      );
    });

    test('sin sesión: onboarding la primera vez, luego ingreso', () {
      expect(
        appRedirect(
          session: const SessionSignedOut(),
          onboardingSeen: false,
          location: '/',
        ),
        '/onboarding',
      );
      expect(
        appRedirect(
          session: const SessionSignedOut(),
          onboardingSeen: true,
          location: '/users',
        ),
        '/login',
      );
      expect(
        appRedirect(
          session: const SessionSignedOut(),
          onboardingSeen: true,
          location: '/login',
        ),
        isNull,
      );
    });

    test('con contraseña temporal solo permite cambiarla', () {
      final s = SessionSignedIn(_user(mustChange: true));
      expect(
        appRedirect(session: s, onboardingSeen: true, location: '/'),
        '/change-password',
      );
      expect(
        appRedirect(
          session: s,
          onboardingSeen: true,
          location: '/change-password',
        ),
        isNull,
      );
    });

    test('con sesión no vuelve al ingreso ni al onboarding', () {
      final s = SessionSignedIn(_user());
      expect(
        appRedirect(session: s, onboardingSeen: true, location: '/login'),
        '/',
      );
      expect(
        appRedirect(session: s, onboardingSeen: true, location: '/onboarding'),
        '/',
      );
      expect(
        appRedirect(session: s, onboardingSeen: true, location: '/inventory'),
        isNull,
      );
    });

    test('Usuarios es solo para administradores', () {
      expect(
        appRedirect(
          session: SessionSignedIn(_user()),
          onboardingSeen: true,
          location: '/users',
        ),
        '/',
      );
      expect(
        appRedirect(
          session: SessionSignedIn(_user(role: Role.admin)),
          onboardingSeen: true,
          location: '/users',
        ),
        isNull,
      );
    });

    test('destino del splash', () {
      expect(
        routeAfterSplash(
          session: SessionSignedIn(_user()),
          onboardingSeen: false,
        ),
        '/',
      );
      expect(
        routeAfterSplash(
          session: const SessionSignedOut(),
          onboardingSeen: false,
        ),
        '/onboarding',
      );
      expect(
        routeAfterSplash(
          session: const SessionSignedOut(),
          onboardingSeen: true,
        ),
        '/login',
      );
    });
  });
}
