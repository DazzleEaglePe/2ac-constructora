import 'dart:io';

import 'package:a2c_inventario/core/storage/local_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late File file;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('a2c-offline-');
    file = File('${directory.path}${Platform.pathSeparator}inventory.sqlite');
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test(
    'cache and queued movement survive closing and reopening Drift',
    () async {
      final firstOpen = LocalDatabase(NativeDatabase(file));
      await firstOpen.putCache('sites:list', [
        {'id': 'site-1', 'name': 'Almacén'},
      ]);
      await firstOpen.enqueueMovement(
        id: 'local-1',
        ownerId: 'user-1',
        idempotencyKey: 'request-1',
        payload: const {
          'assetId': 'asset-1',
          'fromSiteId': 'site-1',
          'toSiteId': 'site-2',
          'quantity': 1,
        },
      );
      await firstOpen.close();

      final reopened = LocalDatabase(NativeDatabase(file));
      addTearDown(reopened.close);
      final cachedSites =
          await reopened.getCache('sites:list') as List<dynamic>;
      final queued = await reopened.pendingForSync('user-1');

      expect(cachedSites.single['name'], 'Almacén');
      expect(queued.single.id, 'local-1');
      expect(queued.single.idempotencyKey, 'request-1');
      expect(queued.single.status, 'PENDIENTE');
    },
  );
}
