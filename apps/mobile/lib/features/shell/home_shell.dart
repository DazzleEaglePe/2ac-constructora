import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/a2c_nav_bar.dart';
import '../auth/application/session_controller.dart';
import '../../core/storage/offline_movements.dart';
import '../../core/storage/pending_movements_sheet.dart';
import '../realtime/realtime_provider.dart';

/// Contenedor con la barra flotante. El operador ve 2 destinos; el
/// administrador, 3 (Usuarios) — docs/08 §2.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(realtimeConnectionProvider);
    ref.watch(offlineSyncProvider);
    final isAdmin = ref.watch(currentUserProvider)?.isAdmin ?? false;
    final userId = ref.watch(currentUserProvider)?.id;
    final items = [
      const A2CNavItem(icon: Icons.home_work_outlined, label: 'Obras'),
      const A2CNavItem(icon: Icons.inventory_2_outlined, label: 'Inventario'),
      if (isAdmin)
        const A2CNavItem(icon: Icons.group_outlined, label: 'Usuarios'),
    ];
    return Scaffold(
      extendBody: true,
      body: Column(
        children: [
          if (userId != null) _OfflineBanner(ownerId: userId),
          Expanded(child: shell),
        ],
      ),
      bottomNavigationBar: A2CNavBar(
        items: items,
        currentIndex: shell.currentIndex.clamp(0, items.length - 1),
        onTap: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}

class _OfflineBanner extends ConsumerWidget {
  const _OfflineBanner({required this.ownerId});

  final String ownerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(connectivityStatusProvider).asData?.value;
    final cacheFetchedAt = ref
        .watch(offlineCacheFetchedAtProvider)
        .asData
        ?.value;
    final movements =
        ref.watch(pendingMovementsProvider(ownerId)).asData?.value ?? const [];
    final offline =
        connection == null || connection.contains(ConnectivityResult.none);
    final pending = movements.where((item) => item.status != 'ENVIADO').length;
    if (!offline && pending == 0) return const SizedBox.shrink();
    final offlineLabel = cacheFetchedAt == null
        ? 'Sin conexión · sin datos guardados'
        : _offlineLabel(DateTime.now().toUtc().difference(cacheFetchedAt));
    return Material(
      color: offline ? const Color(0xFFFFF0CC) : const Color(0xFFFFF6E5),
      child: InkWell(
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => PendingMovementsSheet(ownerId: ownerId),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Row(
              children: [
                Icon(
                  offline ? Icons.cloud_off_outlined : Icons.sync_rounded,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    offline ? offlineLabel : 'Sincronizando movimientos',
                  ),
                ),
                if (pending > 0)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text('$pending pendientes'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _offlineLabel(Duration age) {
    final minutes = age.inMinutes;
    if (minutes < 1) return 'Sin conexión · consulta hace menos de 1 min';
    if (minutes == 1) return 'Sin conexión · consulta hace 1 min';
    return 'Sin conexión · consulta hace $minutes min';
  }
}
