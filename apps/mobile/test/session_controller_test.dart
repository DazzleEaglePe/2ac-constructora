import 'package:a2c_inventario/core/network/api_failure.dart';
import 'package:a2c_inventario/core/storage/token_storage.dart';
import 'package:a2c_inventario/features/auth/application/session_controller.dart';
import 'package:a2c_inventario/features/auth/data/auth_repository.dart';
import 'package:a2c_inventario/features/auth/domain/app_user.dart';
import 'package:a2c_inventario/features/auth/domain/session_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements AuthRepository {}

class _Storage extends Mock implements TokenStorage {}

const _user = AppUser(
  id: 'u1',
  dni: '30456789',
  fullName: 'Carlos Pérez',
  role: Role.admin,
  active: true,
  mustChangePassword: false,
);
const _tokens = TokenPair(accessToken: 'at', refreshToken: 'rt2');

void main() {
  late _Repo repo;
  late _Storage storage;
  late ProviderContainer container;

  setUp(() {
    repo = _Repo();
    storage = _Storage();
    when(() => storage.saveRefreshToken(any())).thenAnswer((_) async {});
    when(() => storage.clear()).thenAnswer((_) async {});
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        tokenStorageProvider.overrideWithValue(storage),
      ],
    );
  });
  tearDown(() => container.dispose());

  SessionController ctrl() => container.read(sessionProvider.notifier);
  SessionState state() => container.read(sessionProvider);

  test('sin refresh token guardado queda sin sesión', () async {
    when(() => storage.readRefreshToken()).thenAnswer((_) async => null);
    await ctrl().restore();
    expect(state(), isA<SessionSignedOut>());
  });

  test('restaura la sesión con el refresh token (RF-AUT-02)', () async {
    when(() => storage.readRefreshToken()).thenAnswer((_) async => 'rt1');
    when(() => repo.refresh('rt1')).thenAnswer((_) async => _tokens);
    when(() => repo.me()).thenAnswer((_) async => _user);

    await ctrl().restore();

    expect((state() as SessionSignedIn).user.id, 'u1');
    expect(container.read(accessTokenHolderProvider).token, 'at');
    verify(() => storage.saveRefreshToken('rt2')).called(1);
  });

  test('si el refresh token es rechazado, borra la sesión guardada', () async {
    when(() => storage.readRefreshToken()).thenAnswer((_) async => 'rt1');
    when(() => repo.refresh('rt1')).thenThrow(
      const ApiFailure(code: 'NO_AUTENTICADO', message: 'x', status: 401),
    );

    await ctrl().restore();

    expect(state(), isA<SessionSignedOut>());
    verify(() => storage.clear()).called(1);
  });

  test('ingresar guarda los tokens y expone al usuario', () async {
    when(
      () =>
          repo.login(dni: '30456789', password: 'Clave2026a', deviceName: null),
    ).thenAnswer((_) async => const LoginResult(_tokens, _user));

    await ctrl().login(dni: '30456789', password: 'Clave2026a');

    expect(container.read(currentUserProvider)?.fullName, 'Carlos Pérez');
    verify(() => storage.saveRefreshToken('rt2')).called(1);
  });

  test('varias renovaciones simultáneas comparten una sola llamada', () async {
    when(() => storage.readRefreshToken()).thenAnswer((_) async => 'rt1');
    when(() => repo.refresh('rt1')).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return _tokens;
    });

    final results = await Future.wait([
      ctrl().renewAccessToken(),
      ctrl().renewAccessToken(),
      ctrl().renewAccessToken(),
    ]);

    expect(results, [true, true, true]);
    verify(() => repo.refresh('rt1')).called(1);
  });

  test('salir borra los tokens aunque falle la red', () async {
    when(() => storage.readRefreshToken()).thenAnswer((_) async => 'rt1');
    when(() => repo.logout('rt1')).thenThrow(ApiFailure.offline);

    await ctrl().logout();

    expect(state(), isA<SessionSignedOut>());
    expect(container.read(accessTokenHolderProvider).token, isNull);
    verify(() => storage.clear()).called(1);
  });
}
