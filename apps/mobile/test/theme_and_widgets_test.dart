import 'package:a2c_inventario/core/l10n/gen/app_localizations.dart';
import 'package:a2c_inventario/core/theme/a2c_colors.dart';
import 'package:a2c_inventario/core/theme/a2c_theme.dart';
import 'package:a2c_inventario/shared/domain/asset_status.dart';
import 'package:a2c_inventario/shared/widgets/a2c_buttons.dart';
import 'package:a2c_inventario/shared/widgets/a2c_chips.dart';
import 'package:a2c_inventario/shared/widgets/a2c_logo.dart';
import 'package:a2c_inventario/shared/widgets/a2c_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: A2CTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  test('el tema usa el amarillo A2C como primario con texto negro', () {
    final theme = A2CTheme.light();
    expect(theme.colorScheme.primary, A2CColors.brandYellow);
    expect(theme.colorScheme.onPrimary, A2CColors.ink);
    expect(theme.textTheme.bodyLarge?.fontFamily, 'Geist');
  });

  test('AssetStatus convierte desde y hacia la API', () {
    expect(AssetStatus.fromApi('MANTENIMIENTO'), AssetStatus.mantenimiento);
    expect(AssetStatus.baja.apiValue, 'BAJA');
  });

  testWidgets('StatusBadge muestra el texto de cada estado', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Column(
          children: [
            StatusBadge(status: AssetStatus.operativo),
            StatusBadge(status: AssetStatus.mantenimiento),
            StatusBadge(status: AssetStatus.baja),
          ],
        ),
      ),
    );
    expect(find.text('Operativo'), findsOneWidget);
    expect(find.text('Mantenimiento'), findsOneWidget);
    expect(find.text('Baja'), findsOneWidget);
  });

  testWidgets('A2CPrimaryButton ejecuta onPressed y respeta el área táctil', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(A2CPrimaryButton(label: 'Ingresar', onPressed: () => taps++)),
    );
    await tester.tap(find.text('Ingresar'));
    expect(taps, 1);
    expect(
      tester.getSize(find.byType(A2CPrimaryButton)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('A2CPrimaryButton en carga no se puede tocar', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        A2CPrimaryButton(
          label: 'Guardar',
          loading: true,
          onPressed: () => taps++,
        ),
      ),
    );
    await tester.tap(find.byType(A2CPrimaryButton));
    expect(taps, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('A2CNavBar marca el destino activo y notifica toques', (
    tester,
  ) async {
    var selected = 0;
    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, setState) => A2CNavBar(
            currentIndex: selected,
            onTap: (i) => setState(() => selected = i),
            items: const [
              A2CNavItem(icon: Icons.home_work_outlined, label: 'Obras'),
              A2CNavItem(icon: Icons.inventory_2_outlined, label: 'Inventario'),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Obras'), findsOneWidget); // solo el activo muestra texto
    expect(find.text('Inventario'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Inventario'));
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(find.text('Inventario'), findsOneWidget);
  });

  testWidgets('A2CLogo respeta la proporción 320×120 y es accesible', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const A2CLogo(height: 60)));
    final size = tester.getSize(find.byType(CustomPaint).last);
    expect(size.width / size.height, closeTo(320 / 120, 0.01));
    expect(find.bySemanticsLabel('Constructora A2C'), findsOneWidget);
  });
}
