import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/a2c_colors.dart';
import '../../core/theme/a2c_dimens.dart';
import '../../core/theme/a2c_typography.dart';
import '../../shared/widgets/a2c_buttons.dart';
import '../../shared/widgets/empty_state.dart';
import '../auth/application/session_controller.dart';

/// Panel (tab Obras). En S1 muestra el encabezado y el estado vacío; las obras
/// llegan en S2 y el tiempo real en S5.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final firstName = user?.fullName.split(' ').first ?? '';
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Buen día'
        : (hour < 19 ? 'Buenas tardes' : 'Buenas noches');

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            A2CSpace.screen,
            16,
            A2CSpace.screen,
            120,
          ),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: A2CColors.ink,
                  foregroundColor: A2CColors.onInk,
                  child: Text(
                    user?.initials ?? '',
                    style: A2CText.bodyStrong.copyWith(color: A2CColors.onInk),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: const ShapeDecoration(
                    color: A2CColors.surface,
                    shape: StadiumBorder(
                      side: BorderSide(color: A2CColors.border),
                    ),
                  ),
                  child: Text(
                    user?.role.label ?? '',
                    style: A2CText.label.copyWith(color: A2CColors.ink),
                  ),
                ),
                const Spacer(),
                A2CIconButton(
                  icon: Icons.logout_rounded,
                  semanticLabel: 'Salir',
                  onPressed: () => ref.read(sessionProvider.notifier).logout(),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              '$greeting, $firstName',
              textAlign: TextAlign.center,
              style: A2CText.bodyStrong.copyWith(color: A2CColors.inkSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu inventario,\nen tiempo real',
              textAlign: TextAlign.center,
              style: A2CText.headline.copyWith(fontSize: 34),
            ),
            const SizedBox(height: 28),
            const EmptyState(
              icon: Icons.home_work_outlined,
              title: 'Aún no hay obras',
              message: 'Aquí verás cada obra con sus herramientas y máquinas, y el almacén central.',
            ),
          ],
        ),
      ),
    );
  }
}
