import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_failure.dart';
import '../../core/theme/a2c_colors.dart';
import '../../core/theme/a2c_dimens.dart';
import '../../core/theme/a2c_typography.dart';
import '../../features/assets/data/assets_repository.dart';
import '../../features/auth/application/session_controller.dart';
import '../../features/dashboard/data/dashboard_repository.dart';
import '../../features/dashboard/domain/dashboard_data.dart';
import '../../features/movements/data/movements_repository.dart';
import '../../features/movements/domain/movement.dart';
import '../../features/sites/domain/site.dart';
import '../realtime/realtime_provider.dart';
import '../../shared/widgets/a2c_buttons.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/a2c_cards.dart';
import '../auth/domain/app_user.dart';

/// Panel de obras con resumen del almacén central y accesos al detalle.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final dashboard = ref.watch(dashboardProvider);
    final recentlyUpdatedSites = ref.watch(recentSiteUpdatesProvider);
    final firstName = user?.fullName.split(' ').first ?? '';
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Buen día'
        : (hour < 19 ? 'Buenas tardes' : 'Buenas noches');

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: A2CColors.ink,
          onRefresh: () => ref.refresh(dashboardProvider.future),
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
                      style: A2CText.bodyStrong.copyWith(
                        color: A2CColors.onInk,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const _LiveIndicator(),
                  const SizedBox(width: 8),
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
                    onPressed: () =>
                        ref.read(sessionProvider.notifier).logout(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                '$greeting, $firstName',
                textAlign: TextAlign.center,
                style: A2CText.bodyStrong.copyWith(
                  color: A2CColors.inkSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Tu inventario,\nen tiempo real',
                      style: A2CText.headline.copyWith(fontSize: 32),
                    ),
                  ),
                  if (user?.isAdmin ?? false)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Auditoría',
                          onPressed: () => context.push('/audit'),
                          icon: const Icon(Icons.history_rounded),
                        ),
                        IconButton.filled(
                          tooltip: 'Nueva obra',
                          onPressed: () => context.push('/sites/new'),
                          icon: const Icon(Icons.add_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: A2CColors.brandYellow,
                            foregroundColor: A2CColors.ink,
                            fixedSize: const Size(52, 52),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  final query = value.trim();
                  ref
                      .read(assetSearchQueryProvider.notifier)
                      .update(q: query, type: null, status: null);
                  context.go('/inventory');
                },
                decoration: InputDecoration(
                  hintText: 'Buscar herramienta o código',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    tooltip: 'Abrir inventario',
                    onPressed: () => context.go('/inventory'),
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.inventory_2_outlined, size: 18),
                    label: const Text('Ver inventario'),
                    onPressed: () => context.go('/inventory'),
                  ),
                  if (user?.isAdmin ?? false)
                    ActionChip(
                      avatar: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Agregar activo'),
                      onPressed: () => context.push('/inventory/assets/new'),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              ...dashboard.when(
                loading: () => [
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: A2CLoadingSkeleton(
                      label: 'Cargando el panel y las obras',
                      rows: 3,
                    ),
                  ),
                ],
                error: (error, _) => [
                  EmptyState(
                    icon: Icons.cloud_off_rounded,
                    title: 'No se pudieron cargar las obras',
                    message: error is ApiFailure
                        ? error.message
                        : 'Revisa la conexión e inténtalo de nuevo.',
                    actionLabel: 'Reintentar',
                    onAction: () => ref.invalidate(dashboardProvider),
                  ),
                ],
                data: (data) => [
                  _DashboardMetrics(totals: data.totals),
                  if (user?.isAdmin ?? false) ...[
                    const SizedBox(height: 18),
                    const _OpenObservations(),
                  ],
                  const SizedBox(height: 18),
                  ..._siteList(
                    context,
                    [
                      ...data.sites,
                      if (data.warehouse != null) data.warehouse!,
                    ],
                    user,
                    recentlyUpdatedSites,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _siteList(
    BuildContext context,
    List<Site> sites,
    AppUser? user,
    Set<String> recentlyUpdatedSites,
  ) {
    final warehouse = sites.where((site) => site.isWarehouse).firstOrNull;
    final projects = sites.where((site) => !site.isWarehouse).toList();
    if (warehouse == null && projects.isEmpty) {
      return [
        const EmptyState(
          icon: Icons.home_work_outlined,
          title: 'Aún no hay obras',
          message: 'Aquí verás las ubicaciones con sus herramientas, máquinas y stock.',
        ),
      ];
    }
    return [
      if (warehouse != null) ...[
        _SiteCard(
          site: warehouse,
          featured: true,
          recentlyUpdated: recentlyUpdatedSites.contains(warehouse.id),
        ),
        const SizedBox(height: 22),
      ],
      if (projects.isNotEmpty) ...[
        Row(
          children: [
            const Expanded(child: Text('Obras', style: A2CText.title)),
            Text(
              '${projects.where((site) => !site.isClosed).length} activas',
              style: A2CText.caption,
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final site in projects) ...[
          _SiteCard(
            site: site,
            recentlyUpdated: recentlyUpdatedSites.contains(site.id),
          ),
          const SizedBox(height: 10),
        ],
      ] else if (user?.isAdmin ?? false) ...[
        const EmptyState(
          icon: Icons.add_business_outlined,
          title: 'Aún no hay obras',
          message: 'Usa el botón + para registrar la primera obra.',
        ),
      ],
    ];
  }
}

class _LiveIndicator extends ConsumerWidget {
  const _LiveIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected =
        ref.watch(realtimeConnectionProvider).asData?.value ?? false;
    final color = connected ? const Color(0xFF16794B) : A2CColors.inkTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: connected ? const Color(0xFFE7F4EC) : A2CColors.surface,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            connected ? 'En vivo' : 'Conectando',
            style: A2CText.caption.copyWith(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _DashboardMetrics extends StatelessWidget {
  const _DashboardMetrics({required this.totals});

  final DashboardTotals totals;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 9,
    runSpacing: 9,
    children: [
      _MetricTile(
        label: 'En obras',
        value: '${totals.unitsOnSites}',
        icon: Icons.apartment_rounded,
      ),
      _MetricTile(
        label: 'Almacén',
        value: '${totals.warehouseUnits}',
        icon: Icons.warehouse_outlined,
      ),
      _MetricTile(
        label: 'Obras activas',
        value: '${totals.activeSites}',
        icon: Icons.location_on_outlined,
      ),
      _MetricTile(
        label: 'Mantenimiento',
        value: '${totals.assetsInMaintenance}',
        icon: Icons.build_circle_outlined,
      ),
    ],
  );
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: (MediaQuery.sizeOf(context).width - A2CSpace.screen * 2 - 9) / 2,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: A2CColors.surface,
        border: Border.all(color: A2CColors.border),
        borderRadius: BorderRadius.circular(A2CRadii.md),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: A2CColors.inkSecondary),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: A2CText.bodyStrong.copyWith(fontSize: 20)),
                Text(
                  label,
                  style: A2CText.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _OpenObservations extends ConsumerWidget {
  const _OpenObservations();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final observations = ref.watch(openObservationsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Observaciones abiertas', style: A2CText.title),
        const SizedBox(height: 9),
        ...observations.when(
          loading: () => [
            const A2CLoadingSkeleton(
              label: 'Cargando observaciones abiertas',
              rows: 1,
            ),
          ],
          error: (error, _) => [
            EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'No se pudieron cargar las observaciones',
              message: error is ApiFailure
                  ? error.message
                  : 'Inténtalo de nuevo.',
              actionLabel: 'Reintentar',
              onAction: () => ref.invalidate(openObservationsProvider),
            ),
          ],
          data: (items) => items.isEmpty
              ? [
                  const EmptyState(
                    icon: Icons.task_alt_rounded,
                    title: 'Todo atendido',
                    message: 'No hay observaciones pendientes.',
                  ),
                ]
              : [
                  for (final item in items.take(4))
                    _ObservationCard(
                      observation: item,
                      onResolve: () => _resolve(context, ref, item),
                    ),
                ],
        ),
      ],
    );
  }

  Future<void> _resolve(
    BuildContext context,
    WidgetRef ref,
    OpenObservation item,
  ) async {
    final controller = TextEditingController();
    final resolution = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atender observación'),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Describe cómo se atendió',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().length >= 3) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (resolution == null) return;
    try {
      await ref
          .read(movementsRepositoryProvider)
          .resolveObservation(item.id, resolution);
      ref.invalidate(openObservationsProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(assetMovementHistoryProvider(item.assetId));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Observación atendida.')));
      }
    } on ApiFailure catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

class _ObservationCard extends StatelessWidget {
  const _ObservationCard({required this.observation, required this.onResolve});
  final OpenObservation observation;
  final VoidCallback onResolve;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: A2CCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${observation.assetName} · ${observation.type}',
            style: A2CText.bodyStrong,
          ),
          const SizedBox(height: 4),
          Text(observation.description, style: A2CText.body),
          const SizedBox(height: 4),
          Text(
            '${observation.fromName ?? 'Ingreso'} → ${observation.toName ?? 'Salida'}',
            style: A2CText.caption,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onResolve,
              icon: const Icon(Icons.task_alt_rounded, size: 18),
              label: const Text('Marcar atendida'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SiteCard extends StatelessWidget {
  const _SiteCard({
    required this.site,
    this.featured = false,
    this.recentlyUpdated = false,
  });

  final Site site;
  final bool featured;
  final bool recentlyUpdated;

  @override
  Widget build(BuildContext context) {
    final color = featured ? A2CColors.onInk : A2CColors.ink;
    final secondary = featured
        ? A2CColors.onInkSecondary
        : A2CColors.inkSecondary;
    final background = featured
        ? A2CColors.ink
        : (recentlyUpdated
              ? A2CColors.brandYellow.withValues(alpha: 0.20)
              : A2CColors.surface);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 420),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(A2CRadii.lg),
        border: Border.all(
          color: recentlyUpdated && !featured
              ? A2CColors.brandYellow
              : (featured ? A2CColors.ink : A2CColors.border),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(A2CRadii.lg),
          onTap: () => context.push('/sites/${site.id}'),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      featured
                          ? Icons.warehouse_outlined
                          : Icons.apartment_rounded,
                      color: featured ? A2CColors.brandYellow : A2CColors.ink,
                      size: 21,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        site.name,
                        style: A2CText.title.copyWith(color: color),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (site.isClosed)
                      _SiteStatusBadge(label: 'Cerrada', dark: featured),
                    if (!site.isClosed && !featured)
                      const _SiteStatusBadge(label: 'Activa'),
                    if (featured)
                      const Icon(
                        Icons.north_east_rounded,
                        color: A2CColors.brandYellow,
                      ),
                  ],
                ),
                if (!site.isWarehouse && site.ownerName != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Responsable · ${site.ownerName}',
                    style: A2CText.caption.copyWith(color: secondary),
                  ),
                ],
                if (site.address != null && site.address!.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    site.address!,
                    style: A2CText.caption.copyWith(color: secondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      '${site.summary.units}',
                      style: A2CText.metric.copyWith(
                        color: featured ? A2CColors.brandYellow : A2CColors.ink,
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'unidades',
                      style: A2CText.label.copyWith(color: secondary),
                    ),
                    const SizedBox(width: 18),
                    Text(
                      '${site.summary.assetCount}',
                      style: A2CText.bodyStrong.copyWith(color: color),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'tipos de activo',
                      style: A2CText.caption.copyWith(color: secondary),
                    ),
                  ],
                ),
                if (site.summary.topItems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final item in site.summary.topItems.take(3))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: featured
                                ? const Color(0x29FFFFFF)
                                : const Color(0x0F000000),
                            borderRadius: BorderRadius.circular(A2CRadii.pill),
                          ),
                          child: Text(
                            '${item.name} ×${item.quantity}',
                            style: A2CText.caption.copyWith(color: color),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SiteStatusBadge extends StatelessWidget {
  const _SiteStatusBadge({required this.label, this.dark = false});

  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: ShapeDecoration(
      color: dark ? const Color(0x29FFFFFF) : A2CColors.brandYellowSoft,
      shape: const StadiumBorder(),
    ),
    child: Text(
      label,
      style: A2CText.caption.copyWith(
        color: dark ? A2CColors.onInk : A2CColors.goldText,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
