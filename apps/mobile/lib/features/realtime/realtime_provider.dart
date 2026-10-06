import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_env.dart';
import '../../core/storage/token_storage.dart';
import '../assets/data/assets_repository.dart';
import '../auth/application/session_controller.dart';
import '../auth/domain/session_state.dart';
import '../dashboard/data/dashboard_repository.dart';
import '../movements/data/movements_repository.dart';
import '../sites/data/sites_repository.dart';
import 'realtime_client.dart';

final realtimeConnectionProvider = StreamProvider.autoDispose<bool>((ref) {
  final session = ref.watch(sessionProvider);
  final token = ref.watch(accessTokenHolderProvider).token;
  if (session is! SessionSignedIn || token == null) return Stream.value(false);

  final client = RealtimeClient(
    url: AppEnv.wsUrl,
    accessToken: token,
    refreshToken: () async {
      final renewed = await ref
          .read(sessionProvider.notifier)
          .renewAccessToken();
      return renewed ? ref.read(accessTokenHolderProvider).token : null;
    },
    onEvent: (event, payload) => _resync(ref, event, payload),
    onSessionRevoked: () => ref.read(sessionProvider.notifier).logout(),
  );
  ref.onDispose(client.dispose);
  return client.connection;
});

class RecentSiteUpdatesController extends Notifier<Set<String>> {
  final Map<String, Timer> _timers = {};

  @override
  Set<String> build() {
    ref.onDispose(() {
      for (final timer in _timers.values) {
        timer.cancel();
      }
    });
    return const {};
  }

  void flash(String id) {
    _timers.remove(id)?.cancel();
    state = {...state, id};
    _timers[id] = Timer(const Duration(milliseconds: 1500), () {
      _timers.remove(id);
      state = {...state}..remove(id);
    });
  }
}

final recentSiteUpdatesProvider =
    NotifierProvider<RecentSiteUpdatesController, Set<String>>(
      RecentSiteUpdatesController.new,
    );

void _resync(Ref ref, String event, dynamic payload) {
  ref
    ..invalidate(dashboardProvider)
    ..invalidate(sitesListProvider);
  invalidateAssetCatalog(ref);
  if (payload is! Map) return;
  final id = payload['id'];
  final assetId = payload['assetId'];
  if (event == 'site.updated' && id is String) {
    ref.read(recentSiteUpdatesProvider.notifier).flash(id);
    ref.invalidate(siteDetailProvider(id));
  }
  if (event == 'asset.updated' && id is String) {
    ref.invalidate(assetDetailProvider(id));
  }
  if (assetId is String) {
    ref
      ..invalidate(assetDetailProvider(assetId))
      ..invalidate(assetMovementHistoryProvider(assetId));
  }
  final siteIds = payload['siteIds'];
  if (siteIds is List) {
    for (final siteId in siteIds.whereType<String>()) {
      ref.read(recentSiteUpdatesProvider.notifier).flash(siteId);
      ref
        ..invalidate(siteDetailProvider(siteId))
        ..invalidate(siteStockProvider(siteId))
        ..invalidate(siteMovementHistoryProvider(siteId));
    }
  }
}
