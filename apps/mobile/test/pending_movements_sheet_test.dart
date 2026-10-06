import 'package:a2c_inventario/core/storage/local_database.dart';
import 'package:a2c_inventario/core/storage/pending_movements_sheet.dart';
import 'package:a2c_inventario/core/theme/a2c_theme.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LocalDatabase database;

  setUp(() {
    database = LocalDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  Widget buildSheet() => ProviderScope(
    overrides: [localDatabaseProvider.overrideWithValue(database)],
    child: MaterialApp(
      theme: A2CTheme.light(),
      home: const Scaffold(body: PendingMovementsSheet(ownerId: 'user-1')),
    ),
  );

  Future<void> disposeSheet(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('la cola vacía presenta un estado accesible', (tester) async {
    await tester.pumpWidget(buildSheet());
    await tester.pumpAndSettle();

    expect(find.text('Todo sincronizado'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Todo sincronizado. No hay movimientos pendientes.',
      ),
      findsOneWidget,
    );
    await disposeSheet(tester);
  });

  testWidgets('un movimiento rechazado identifica activo y motivo', (
    tester,
  ) async {
    await database.enqueueMovement(
      id: 'movement-rejected',
      ownerId: 'user-1',
      idempotencyKey: 'request-1',
      payload: const {
        'assetId': 'asset-id',
        'assetName': 'Taladro percutor',
        'assetCode': 'HER-0001',
        'fromSiteId': 'site-1',
        'toSiteId': 'site-2',
        'quantity': 4,
      },
    );
    await database.setMovementStatus(
      'movement-rejected',
      status: 'RECHAZADO',
      error: 'Solo hay 2 unidades disponibles.',
    );

    await tester.pumpWidget(buildSheet());
    await tester.pumpAndSettle();

    expect(find.textContaining('Taladro percutor · HER-0001'), findsOneWidget);
    expect(
      find.textContaining('Solo hay 2 unidades disponibles.'),
      findsOneWidget,
    );
    expect(find.text('Corregir'), findsOneWidget);
    await disposeSheet(tester);
  });

  testWidgets('corregir un movimiento inválido anuncia qué debe cambiar', (
    tester,
  ) async {
    await database.putCache('sites:list', [
      {'id': 'site-1', 'name': 'Obra Norte'},
      {'id': 'site-2', 'name': 'Almacén'},
    ]);
    await database.enqueueMovement(
      id: 'movement-invalid',
      ownerId: 'user-1',
      idempotencyKey: 'request-2',
      payload: const {
        'assetId': 'asset-id',
        'fromSiteId': 'site-1',
        'toSiteId': 'site-1',
        'quantity': 1,
      },
    );
    await database.setMovementStatus(
      'movement-invalid',
      status: 'RECHAZADO',
      error: 'El origen y el destino no pueden coincidir.',
    );

    await tester.pumpWidget(buildSheet());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Corregir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar y reintentar'));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('El origen y el destino deben ser distintos.'),
      findsOneWidget,
    );
    expect(find.byType(AlertDialog), findsOneWidget);
    await disposeSheet(tester);
  });
}
