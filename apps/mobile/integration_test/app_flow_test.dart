import 'package:a2c_inventario/app.dart';
import 'package:a2c_inventario/core/config/app_env.dart';
import 'package:a2c_inventario/core/storage/preferences.dart';
import 'package:a2c_inventario/core/storage/token_storage.dart';
import 'package:a2c_inventario/features/assets/presentation/new_asset_screen.dart';
import 'package:a2c_inventario/features/sites/presentation/new_site_screen.dart';
import 'package:a2c_inventario/features/sites/presentation/site_detail_screen.dart';
import 'package:a2c_inventario/features/shell/inventory_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _dni = String.fromEnvironment('INTEGRATION_TEST_DNI');
const _password = String.fromEnvironment('INTEGRATION_TEST_PASSWORD');
const _allowMutations = String.fromEnvironment(
  'INTEGRATION_TEST_ALLOW_MUTATIONS',
);

String? get _skipReason {
  if (_dni.isEmpty || _password.isEmpty) {
    return 'Configura las credenciales de un administrador de integración.';
  }
  if (_allowMutations != 'true') {
    return 'Activa INTEGRATION_TEST_ALLOW_MUTATIONS solo para la base aislada.';
  }
  return null;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'ingresa, crea una obra y un activo, y registra su movimiento',
    (tester) async {
      _assertIsolatedTarget();
      SharedPreferences.setMockInitialValues({'a2c.onboarding_seen': true});
      final preferences = await SharedPreferences.getInstance();
      await initializeDateFormatting('es');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            tokenStorageProvider.overrideWithValue(_MemoryTokenStorage()),
          ],
          child: const A2CApp(),
        ),
      );

      await _pumpUntil(tester, find.text('Ingresa a tu cuenta'));
      final loginFields = find.byType(TextFormField);
      await tester.enterText(loginFields.at(0), _dni);
      await tester.enterText(loginFields.at(1), _password);
      await tester.tap(find.text('Ingresar'));
      await _pumpUntil(tester, find.textContaining('Tu inventario'));

      final uniqueId = DateTime.now().microsecondsSinceEpoch;
      final siteName = 'IT Obra $uniqueId';
      final assetName = 'IT Herramienta $uniqueId';

      await tester.tap(find.byTooltip('Nueva obra'));
      await _pumpUntil(tester, find.byType(NewSiteScreen));
      final siteFields = find.byType(TextFormField);
      await tester.enterText(siteFields.at(0), siteName);
      await tester.enterText(siteFields.at(1), 'Operador de integración');
      await tester.tap(find.text('Guardar obra'));
      await _pumpUntilAbsent(tester, find.byType(NewSiteScreen));
      await _pumpUntil(tester, find.byType(SiteDetailScreen));

      await tester.tap(find.bySemanticsLabel('Inventario'));
      await tester.pumpAndSettle();
      await _pumpUntil(tester, find.byType(InventoryScreen));
      await tester.tap(find.byTooltip('Agregar activo'));
      await _pumpUntil(tester, find.byType(NewAssetScreen));
      await tester.enterText(find.byType(TextFormField).first, assetName);

      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(siteName).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar activo'));
      await _pumpUntilAbsent(tester, find.byType(NewAssetScreen));

      final inventorySearch = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Buscar por nombre o código',
      );
      await tester.enterText(inventorySearch, assetName);
      await tester.pump(const Duration(milliseconds: 400));
      await _pumpUntil(tester, find.text(assetName));
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.text(assetName).last);
      await _pumpUntil(tester, find.text('Registrar movimiento'));

      await tester.tap(find.text('Registrar movimiento'));
      await _pumpUntil(tester, find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await _pumpUntil(tester, find.text('Confirma el movimiento'));
      await tester.tap(find.text('Confirmar movimiento'));
      await _pumpUntil(tester, find.text('Movimiento registrado.'));
    },
    skip: _skipReason != null,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

void _assertIsolatedTarget() {
  final uri = Uri.parse(AppEnv.apiBaseUrl);
  const localHosts = {'localhost', '127.0.0.1', '::1', '10.0.2.2'};
  if (AppEnv.name != 'integration' || !localHosts.contains(uri.host)) {
    throw StateError(
      'El flujo de integración solo puede modificar una API local con ENV=integration.',
    );
  }
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 120; attempt++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 250));
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  final visibleText = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data)
      .whereType<String>()
      .join(' · ');
  expect(finder, findsOneWidget, reason: 'Texto visible: $visibleText');
}

Future<void> _pumpUntilAbsent(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 120; attempt++) {
    if (finder.evaluate().isEmpty) return;
    await tester.pump(const Duration(milliseconds: 250));
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  expect(finder, findsNothing);
}

class _MemoryTokenStorage implements TokenStorage {
  String? _refreshToken;

  @override
  Future<String?> readRefreshToken() async => _refreshToken;

  @override
  Future<void> saveRefreshToken(String token) async => _refreshToken = token;

  @override
  Future<void> clear() async => _refreshToken = null;

  String? _rememberedDni;

  @override
  Future<String?> readRememberedDni() async => _rememberedDni;

  @override
  Future<void> saveRememberedDni(String dni) async => _rememberedDni = dni;

  @override
  Future<void> clearRememberedDni() async => _rememberedDni = null;
}
