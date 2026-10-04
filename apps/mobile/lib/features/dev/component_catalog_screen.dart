import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_env.dart';
import '../../core/l10n/gen/app_localizations.dart';
import '../../core/network/dio_client.dart';
import '../../core/theme/a2c_colors.dart';
import '../../core/theme/a2c_dimens.dart';
import '../../core/theme/a2c_typography.dart';
import '../../shared/domain/asset_status.dart';
import '../../shared/widgets/a2c_buttons.dart';
import '../../shared/widgets/a2c_cards.dart';
import '../../shared/widgets/a2c_chips.dart';
import '../../shared/widgets/a2c_logo.dart';
import '../../shared/widgets/a2c_nav_bar.dart';
import '../../shared/widgets/a2c_text_field.dart';

/// Catálogo de componentes A2C (solo en `ENV=dev`). Sirve para revisar el
/// sistema de diseño en un dispositivo real (Sprint 0).
class ComponentCatalogScreen extends ConsumerStatefulWidget {
  const ComponentCatalogScreen({super.key});

  @override
  ConsumerState<ComponentCatalogScreen> createState() =>
      _ComponentCatalogScreenState();
}

class _ComponentCatalogScreenState
    extends ConsumerState<ComponentCatalogScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final health = ref.watch(apiHealthProvider);

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            A2CSpace.screen,
            24,
            A2CSpace.screen,
            120,
          ),
          children: [
            const A2CLogo(height: 36),
            const SizedBox(height: A2CSpace.lg),
            const Text('Catálogo de componentes', style: A2CText.headline),
            const Text(
              'Entorno ${AppEnv.name} · ${AppEnv.apiBaseUrl}',
              style: A2CText.caption,
            ),
            const SizedBox(height: A2CSpace.md),
            _ApiStatus(
              state: health,
              onRetry: () => ref.invalidate(apiHealthProvider),
              onlineLabel: l10n.apiOnline,
              offlineLabel: l10n.apiOffline,
            ),
            const _Section('Color'),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Swatch('brandYellow', A2CColors.brandYellow),
                _Swatch('ink', A2CColors.ink),
                _Swatch('inkSecondary', A2CColors.inkSecondary),
                _Swatch('goldText', A2CColors.goldText),
                _Swatch('backgroundAlt', A2CColors.backgroundAlt),
                _Swatch('surfaceStrong', A2CColors.surfaceStrong),
              ],
            ),
            const _Section('Tipografía'),
            const Text(
              'Cada herramienta, siempre ubicada',
              style: A2CText.display,
            ),
            const Text('Inventario', style: A2CText.headline),
            const Text('Obra Juan Ramírez', style: A2CText.title),
            const Text(
              'Texto general del cuerpo con Geist.',
              style: A2CText.body,
            ),
            const Text('01 — UBICACIÓN', style: A2CText.overline),
            const Text('23', style: A2CText.metric),
            const Text('HER-0142', style: A2CText.code),
            const _Section('Botones'),
            A2CPrimaryButton(label: 'Confirmar movimiento', onPressed: () {}),
            const SizedBox(height: A2CSpace.md),
            const A2CPrimaryButton(
              label: 'Guardando…',
              onPressed: null,
              loading: true,
            ),
            const SizedBox(height: A2CSpace.md),
            A2CSecondaryButton(
              label: 'Notas (2)',
              icon: Icons.notes_rounded,
              onPressed: () {},
            ),
            const SizedBox(height: A2CSpace.md),
            Row(
              children: [
                A2CIconButton(
                  icon: Icons.arrow_back_rounded,
                  semanticLabel: 'Volver',
                  onPressed: () {},
                ),
                const SizedBox(width: A2CSpace.md),
                A2CFab(
                  semanticLabel: 'Agregar herramienta o equipo',
                  onPressed: () {},
                ),
              ],
            ),
            const _Section('Campos'),
            const A2CTextField(
              label: 'DNI',
              hint: 'Número de documento',
              keyboardType: TextInputType.number,
              maxLength: 8,
            ),
            const SizedBox(height: A2CSpace.md),
            const A2CTextField(
              label: 'Contraseña',
              hint: 'Tu contraseña',
              obscureText: true,
            ),
            const _Section('Chips y estados'),
            const Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                A2CChip(label: 'Trompo', quantity: 1),
                A2CChip(label: 'Palas', quantity: 2),
                A2CChip(label: 'Pico', quantity: 4),
              ],
            ),
            const SizedBox(height: A2CSpace.md),
            const Wrap(
              spacing: 8,
              children: [
                StatusBadge(status: AssetStatus.operativo),
                StatusBadge(status: AssetStatus.mantenimiento),
                StatusBadge(status: AssetStatus.baja),
              ],
            ),
            const _Section('Tarjetas'),
            A2CCard(
              onTap: () {},
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Obra Juan Ramírez', style: A2CText.title),
                  Text('Calle Los Pinos 245', style: A2CText.label),
                  SizedBox(height: A2CSpace.md),
                  Wrap(
                    spacing: 6,
                    children: [
                      A2CChip(label: 'Trompo', quantity: 1),
                      A2CChip(label: 'Palas', quantity: 2),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: A2CSpace.md),
            HighlightCard(
              title: 'Almacén central',
              subtitle: 'Disponible para asignar',
              value: '31',
              unit: 'uds',
              onTap: () {},
            ),
            const _Section('Logo sobre negro'),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: A2CColors.ink,
                borderRadius: BorderRadius.circular(A2CRadii.lg),
              ),
              child: const Center(child: A2CLogo(height: 48, onDark: true)),
            ),
          ],
        ),
      ),
      bottomNavigationBar: A2CNavBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: [
          A2CNavItem(icon: Icons.home_work_outlined, label: l10n.navSites),
          A2CNavItem(
            icon: Icons.inventory_2_outlined,
            label: l10n.navInventory,
          ),
          A2CNavItem(icon: Icons.group_outlined, label: l10n.navUsers),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 32, bottom: 12),
    child: Text(title.toUpperCase(), style: A2CText.overline),
  );
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.name, this.color);

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 104,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(A2CRadii.sm),
            border: Border.all(color: A2CColors.border),
          ),
        ),
        const SizedBox(height: 4),
        Text(name, style: A2CText.caption),
      ],
    ),
  );
}

class _ApiStatus extends StatelessWidget {
  const _ApiStatus({
    required this.state,
    required this.onRetry,
    required this.onlineLabel,
    required this.offlineLabel,
  });

  final AsyncValue<bool> state;
  final VoidCallback onRetry;
  final String onlineLabel;
  final String offlineLabel;

  @override
  Widget build(BuildContext context) {
    final online = state.value ?? false;
    final label = state.isLoading
        ? 'Verificando API…'
        : (online ? onlineLabel : offlineLabel);
    return InkWell(
      onTap: onRetry,
      borderRadius: BorderRadius.circular(A2CRadii.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: const ShapeDecoration(
          color: A2CColors.surface,
          shape: StadiumBorder(side: BorderSide(color: A2CColors.border)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: online ? A2CColors.brandYellow : A2CColors.retiredBorder,
              ),
            ),
            const SizedBox(width: 8),
            Text(label, style: A2CText.label.copyWith(color: A2CColors.ink)),
          ],
        ),
      ),
    );
  }
}
