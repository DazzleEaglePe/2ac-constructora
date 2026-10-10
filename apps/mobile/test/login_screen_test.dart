import 'package:a2c_inventario/core/network/api_failure.dart';
import 'package:a2c_inventario/core/storage/token_storage.dart';
import 'package:a2c_inventario/core/theme/a2c_theme.dart';
import 'package:a2c_inventario/features/auth/data/auth_repository.dart';
import 'package:a2c_inventario/features/auth/domain/app_user.dart';
import 'package:a2c_inventario/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements AuthRepository {}

/// Almacén seguro en memoria.
class _Storage extends Fake implements TokenStorage {
  String? rememberedDni;

  @override
  Future<void> saveRefreshToken(String token) async {}
  @override
  Future<String?> readRememberedDni() async => rememberedDni;
  @override
  Future<void> saveRememberedDni(String dni) async => rememberedDni = dni;
  @override
  Future<void> clearRememberedDni() async => rememberedDni = null;
}

const _user = AppUser(
  id: 'u1',
  dni: '30456789',
  fullName: 'Carlos Pérez',
  role: Role.operador,
  active: true,
  mustChangePassword: false,
);

void main() {
  late _Repo repo;
  late _Storage storage;

  Future<void> pump(WidgetTester tester, {String? rememberedDni}) async {
    repo = _Repo();
    storage = _Storage()..rememberedDni = rememberedDni;
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          tokenStorageProvider.overrideWithValue(storage),
        ],
        child: MaterialApp(theme: A2CTheme.light(), home: const LoginScreen()),
      ),
    );
  }

  testWidgets('valida que el DNI tenga 8 dígitos antes de llamar a la API', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byType(TextFormField).first, '1234');
    await tester.enterText(find.byType(TextFormField).last, 'Clave2026a');
    await tester.tap(find.text('Ingresar'));
    await tester.pump();

    expect(find.text('El DNI tiene 8 dígitos'), findsOneWidget);
    verifyNever(
      () => repo.login(
        dni: any(named: 'dni'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('muestra el error de credenciales que devuelve la API', (
    tester,
  ) async {
    await pump(tester);
    when(
      () =>
          repo.login(dni: '30456789', password: 'malaClave1', deviceName: null),
    ).thenThrow(
      const ApiFailure(
        code: 'CREDENCIALES_INVALIDAS',
        message: 'DNI o contraseña incorrectos',
        status: 401,
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, '30456789');
    await tester.enterText(find.byType(TextFormField).last, 'malaClave1');
    await tester.tap(find.text('Ingresar'));
    await tester.pump();

    expect(find.text('DNI o contraseña incorrectos'), findsOneWidget);
  });

  testWidgets('el campo DNI solo acepta dígitos y máximo 8', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextFormField).first, '12ab345678999');
    expect(find.text('12345678'), findsOneWidget);
  });

  testWidgets('precarga el DNI recordado en este equipo', (tester) async {
    await pump(tester, rememberedDni: '30456789');
    await tester.pump(); // lectura asíncrona del almacén seguro
    expect(find.text('30456789'), findsOneWidget);
    expect(find.text('8/8'), findsOneWidget);
  });

  testWidgets('al ingresar recuerda el DNI si la casilla está marcada', (
    tester,
  ) async {
    await pump(tester);
    when(
      () =>
          repo.login(dni: '30456789', password: 'Clave2026a', deviceName: null),
    ).thenAnswer(
      (_) async => const LoginResult(
        TokenPair(accessToken: 'at', refreshToken: 'rt'),
        _user,
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, '30456789');
    await tester.enterText(find.byType(TextFormField).last, 'Clave2026a');
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();

    expect(storage.rememberedDni, '30456789');
  });

  testWidgets('al desmarcar la casilla olvida el DNI guardado', (tester) async {
    await pump(tester, rememberedDni: '30456789');
    when(
      () =>
          repo.login(dni: '30456789', password: 'Clave2026a', deviceName: null),
    ).thenAnswer(
      (_) async => const LoginResult(
        TokenPair(accessToken: 'at', refreshToken: 'rt'),
        _user,
      ),
    );

    await tester.tap(find.text('Recordar mi DNI en este equipo'));
    await tester.enterText(find.byType(TextFormField).last, 'Clave2026a');
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();

    expect(storage.rememberedDni, isNull);
  });
}
