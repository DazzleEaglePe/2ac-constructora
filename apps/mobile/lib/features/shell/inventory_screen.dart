import 'package:flutter/material.dart';

import '../../core/theme/a2c_dimens.dart';
import '../../core/theme/a2c_typography.dart';
import '../../shared/widgets/empty_state.dart';

/// Inventario general (S3). En S1, estado vacío.
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          A2CSpace.screen,
          28,
          A2CSpace.screen,
          120,
        ),
        children: [
          Text('Inventario', style: A2CText.headline.copyWith(fontSize: 36)),
          const SizedBox(height: 20),
          const EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Aún no hay activos',
            message: 'Las herramientas y máquinas registradas aparecerán aquí, con su stock y ubicación.',
          ),
        ],
      ),
    ),
  );
}
