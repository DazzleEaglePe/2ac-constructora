import 'package:a2c_inventario/core/network/api_failure.dart';
import 'package:a2c_inventario/core/storage/token_storage.dart';
import 'package:a2c_inventario/core/theme/a2c_theme.dart';
import 'package:a2c_inventario/features/auth/data/auth_repository.dart';
import 'package:a2c_inventario/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements AuthRepository {}

class _Storage extends Mock implements TokenStorage {}

void main() {
  late _Repo repo;

  Future<void> pump(WidgetTester tester) async {
    repo = _Repo();
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          tokenStorageProvider.overrideWithValue(_Storage()),
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
}
