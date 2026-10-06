import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/a2c_nav_bar.dart';
import '../auth/application/session_controller.dart';

/// Contenedor con la barra flotante. El operador ve 2 destinos; el
/// administrador, 3 (Usuarios) — docs/08 §2.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(currentUserProvider)?.isAdmin ?? false;
    final items = [
      const A2CNavItem(icon: Icons.home_work_outlined, label: 'Obras'),
      const A2CNavItem(icon: Icons.inventory_2_outlined, label: 'Inventario'),
      if (isAdmin)
        const A2CNavItem(icon: Icons.group_outlined, label: 'Usuarios'),
    ];
    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: A2CNavBar(
        items: items,
        currentIndex: shell.currentIndex.clamp(0, items.length - 1),
        onTap: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}
