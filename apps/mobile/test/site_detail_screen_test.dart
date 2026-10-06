import 'package:a2c_inventario/core/theme/a2c_theme.dart';
import 'package:a2c_inventario/core/l10n/gen/app_localizations.dart';
import 'package:a2c_inventario/features/movements/data/movements_repository.dart';
import 'package:a2c_inventario/features/sites/data/sites_repository.dart';
import 'package:a2c_inventario/features/sites/domain/site.dart';
import 'package:a2c_inventario/features/sites/presentation/site_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'un filtro sin coincidencias no se presenta como ubicación vacía',
    (tester) async {
      const site = Site(
        id: 'site-1',
        type: 'OBRA',
        name: 'Obra de prueba',
        ownerName: null,
        address: null,
        lat: null,
        lng: null,
        status: 'ACTIVA',
        summary: SiteSummary(
          units: 2,
          assetCount: 1,
          lastMovementAt: null,
          topItems: [],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            siteDetailProvider.overrideWith((ref, id) async => site),
            siteStockProvider.overrideWith(
              (ref, id) async => const [
                SiteStockItem(
                  id: 'asset-1',
                  code: 'HER-0001',
                  type: 'HERRAMIENTA',
                  name: 'Taladro',
                  status: 'OPERATIVO',
                  quantity: 2,
                ),
              ],
            ),
            siteMovementHistoryProvider.overrideWith(
              (ref, id) async => const [],
            ),
          ],
          child: MaterialApp(
            theme: A2CTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SiteDetailScreen(siteId: 'site-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Taladro'), findsOneWidget);
      await tester.tap(find.text('Máquinas'));
      await tester.pumpAndSettle();

      expect(find.text('Sin activos con este filtro'), findsOneWidget);
      expect(find.text('Aún no hay activos'), findsNothing);

    await tester.tap(find.text('Todos'));
      await tester.pumpAndSettle();
      expect(find.text('Taladro'), findsOneWidget);
      expect(find.text('Sin activos con este filtro'), findsNothing);
    },
  );
}
