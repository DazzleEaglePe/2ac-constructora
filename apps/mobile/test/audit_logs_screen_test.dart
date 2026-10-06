import 'package:a2c_inventario/core/network/api_failure.dart';
import 'package:a2c_inventario/core/theme/a2c_theme.dart';
import 'package:a2c_inventario/features/audit/data/audit_repository.dart';
import 'package:a2c_inventario/features/audit/domain/audit_log.dart';
import 'package:a2c_inventario/features/audit/presentation/audit_logs_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _AuditRepository extends Mock implements AuditRepository {}

void main() {
  late _AuditRepository repository;

  testWidgets(
    'un error al cargar otra página conserva registros y permite reintentar',
    (tester) async {
      repository = _AuditRepository();
      var continuationAttempts = 0;
      when(() => repository.list(action: '', cursor: null)).thenAnswer(
        (_) async =>
            AuditLogPage(items: [_log('SITE_CREATED')], nextCursor: 'cursor-1'),
      );
      when(() => repository.list(action: '', cursor: 'cursor-1'))
          .thenAnswer((_) async {
            continuationAttempts++;
            if (continuationAttempts == 1) {
              throw const ApiFailure(
                code: 'SERVICIO_NO_DISPONIBLE',
                message: 'No se pudo completar la solicitud.',
                status: 503,
              );
            }
            return AuditLogPage(items: [_log('ASSET_CREATED')]);
          });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [auditRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp(
            theme: A2CTheme.light(),
            home: const AuditLogsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SITE_CREATED'), findsOneWidget);
      await tester.tap(find.text('Cargar más'));
      await tester.pumpAndSettle();

      expect(find.text('SITE_CREATED'), findsOneWidget);
      expect(find.text('No se cargaron más registros'), findsOneWidget);
      expect(find.text('No se pudo completar la solicitud.'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('SITE_CREATED'), findsOneWidget);
      expect(find.text('ASSET_CREATED'), findsOneWidget);
      expect(find.text('No se cargaron más registros'), findsNothing);
    },
  );

  testWidgets(
    'una excepción inesperada al abrir auditoría no deja la carga infinita',
    (tester) async {
      repository = _AuditRepository();
      when(() => repository.list(action: '', cursor: null))
          .thenThrow(StateError('unexpected'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [auditRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp(
            theme: A2CTheme.light(),
            home: const AuditLogsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No se cargó la auditoría'), findsOneWidget);
      expect(find.text('Inténtalo de nuevo.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );
}

AuditLog _log(String action) => AuditLog(
  id: action,
  action: action,
  entityType: 'site',
  entityId: 'test-1',
  createdAt: DateTime.utc(2026, 10, 5),
  userName: 'Usuario de prueba',
  dni: '00000001',
);
