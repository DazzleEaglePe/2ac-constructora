import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'local_database.g.dart';

class CachedResponses extends Table {
  TextColumn get key => text()();
  TextColumn get body => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class PendingMovements extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text()();
  TextColumn get idempotencyKey => text()();
  TextColumn get payload => text()();
  TextColumn get status => text()();
  TextColumn get error => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [CachedResponses, PendingMovements])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'a2c_inventory'));

  @override
  int get schemaVersion => 1;

  Future<void> putCache(String key, Object value) =>
      into(cachedResponses).insertOnConflictUpdate(
        CachedResponsesCompanion.insert(
          key: key,
          body: jsonEncode(value),
          fetchedAt: DateTime.now().toUtc(),
        ),
      );

  Future<Object?> getCache(String key) async {
    final row = await (select(
      cachedResponses,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row == null ? null : jsonDecode(row.body);
  }

  Stream<DateTime?> watchLatestCacheFetchedAt() =>
      (select(cachedResponses)
            ..orderBy([(t) => OrderingTerm.desc(t.fetchedAt)])
            ..limit(1))
          .watch()
          .map((rows) => rows.isEmpty ? null : rows.first.fetchedAt);

  Future<void> enqueueMovement({
    required String id,
    required String ownerId,
    required String idempotencyKey,
    required Map<String, Object?> payload,
  }) => into(pendingMovements).insertOnConflictUpdate(
    PendingMovementsCompanion.insert(
      id: id,
      ownerId: ownerId,
      idempotencyKey: idempotencyKey,
      payload: jsonEncode(payload),
      status: 'PENDIENTE',
      createdAt: DateTime.now().toUtc(),
    ),
  );

  Stream<List<PendingMovement>> watchMovements(String ownerId) =>
      (select(pendingMovements)
            ..where((t) => t.ownerId.equals(ownerId))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();

  Future<List<PendingMovement>> pendingForSync(String ownerId) =>
      (select(pendingMovements)
            ..where(
              (t) => t.ownerId.equals(ownerId) & t.status.equals('PENDIENTE'),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  Future<void> setMovementStatus(
    String id, {
    required String status,
    String? error,
    bool incrementAttempts = false,
  }) async {
    await (update(pendingMovements)..where((t) => t.id.equals(id))).write(
      PendingMovementsCompanion(status: Value(status), error: Value(error)),
    );
    if (incrementAttempts) {
      await customStatement(
        'UPDATE pending_movements SET attempts = attempts + 1 WHERE id = ?',
        [id],
      );
    }
  }

  Future<void> updateMovement({
    required String id,
    required String payload,
    required String idempotencyKey,
  }) async {
    await (update(pendingMovements)..where((t) => t.id.equals(id))).write(
      PendingMovementsCompanion(
        payload: Value(payload),
        idempotencyKey: Value(idempotencyKey),
        status: const Value('PENDIENTE'),
        error: const Value(null),
        attempts: const Value(0),
      ),
    );
  }
}

final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  final database = LocalDatabase();
  ref.onDispose(database.close);
  return database;
});
