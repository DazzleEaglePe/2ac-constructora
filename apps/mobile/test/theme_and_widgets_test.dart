import 'package:a2c_inventario/core/l10n/gen/app_localizations.dart';
import 'package:a2c_inventario/core/theme/a2c_colors.dart';
import 'package:a2c_inventario/core/theme/a2c_theme.dart';
import 'package:a2c_inventario/features/sites/presentation/new_site_screen.dart';
import 'package:a2c_inventario/shared/domain/asset_status.dart';
import 'package:a2c_inventario/shared/widgets/a2c_buttons.dart';
import 'package:a2c_inventario/shared/widgets/a2c_chips.dart';
import 'package:a2c_inventario/shared/widgets/a2c_logo.dart';
import 'package:a2c_inventario/shared/widgets/a2c_nav_bar.dart';
import 'package:a2c_inventario/shared/widgets/empty_state.dart';
import 'package:a2c_inventario/shared/widgets/loading_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          loadingLabel: 'Guardando usuario',
          onPressed: () => taps++,
        ),
      ),
    );
    await tester.tap(find.byType(A2CPrimaryButton));
    expect(taps, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('Guardando usuario'), findsOneWidget);
  });

  testWidgets('los botones admiten etiquetas completas con texto al 130 %', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const primaryLabel = 'Guardar el activo y continuar con el inventario';
    const secondaryLabel = 'Reintentar la conexión con el servidor';
    await tester.pumpWidget(
      MaterialApp(
        theme: A2CTheme.light(),
        home: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  A2CPrimaryButton(label: primaryLabel, onPressed: _noop),
                  SizedBox(height: 12),
                  A2CSecondaryButton(label: secondaryLabel, onPressed: _noop),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text(primaryLabel), findsOneWidget);
    expect(find.text(secondaryLabel), findsOneWidget);
    expect(
      tester.getSize(find.byType(A2CPrimaryButton)).height,
      greaterThan(54),
    );
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

  testWidgets(
    'A2CLogo respeta la proporción del monograma Cota y es accesible',
    (tester) async {
      await tester.pumpWidget(_wrap(const A2CLogo(height: 60)));
      final size = tester.getSize(find.byType(CustomPaint).last);
      expect(size.width / size.height, closeTo(250.8 / 160, 0.01));
      expect(find.bySemanticsLabel('A2 Constructora'), findsOneWidget);
    },
  );

  testWidgets('A2CLogo con cotas ocupa la caja del manual (330 × 247)', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const A2CLogo(height: 100, cotas: true)));
    final size = tester.getSize(find.byType(CustomPaint).last);
    expect(size.width / size.height, closeTo(330 / 247, 0.01));
  });

  testWidgets('el esqueleto anuncia la carga a lectores de pantalla', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const A2CLoadingSkeleton(label: 'Cargando el inventario')),
    );
    final semantics = tester
        .getSemantics(find.byType(A2CLoadingSkeleton))
        .getSemanticsData();
    expect(semantics.label, 'Cargando el inventario');
    expect(semantics.flagsCollection.isLiveRegion, isTrue);
  });

  testWidgets('las listas anuncian la carga una sola vez', (tester) async {
    await tester.pumpWidget(
      _wrap(const A2CLoadingRows(label: 'Cargando usuarios')),
    );
    final semantics = tester
        .getSemantics(find.byType(A2CLoadingRows))
        .getSemanticsData();
    expect(semantics.label, 'Cargando usuarios');
    expect(semantics.flagsCollection.isLiveRegion, isTrue);
  });

  testWidgets(
    'EmptyState sigue visible con texto al 130 % y anuncia el error',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: A2CTheme.light(),
          home: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: Scaffold(
              body: EmptyState(
                icon: Icons.cloud_off,
                title: 'No hay conexión',
                message: 'Revisa la señal e inténtalo otra vez.',
                actionLabel: 'Reintentar',
                onAction: _noop,
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'No hay conexión. Revisa la señal e inténtalo otra vez.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('el formulario de obra conserva etiquetas accesibles al 130 %', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: A2CTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: NewSiteScreen(),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    for (final label in [
      'Nombre de la obra',
      'Responsable',
      'Dirección (opcional)',
      'Latitud (opcional)',
      'Longitud (opcional)',
    ]) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
  });
}

void _noop() {}
