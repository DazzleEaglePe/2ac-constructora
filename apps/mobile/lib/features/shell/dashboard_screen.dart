import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_failure.dart';
import '../../core/theme/a2c_colors.dart';
import '../../core/theme/a2c_dimens.dart';
import '../../core/theme/a2c_typography.dart';
import '../../features/auth/application/session_controller.dart';
import '../../features/sites/data/sites_repository.dart';
import '../../features/sites/domain/site.dart';
import '../../shared/widgets/a2c_buttons.dart';
import '../../shared/widgets/empty_state.dart';
import '../auth/domain/app_user.dart';

/// Panel de obras con resumen del almacén central y accesos al detalle.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final sites = ref.watch(sitesListProvider);
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
          onRefresh: () => ref.refresh(sitesListProvider.future),
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
              const SizedBox(height: 20),
              ...sites.when(
                loading: () => [
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(36),
                      child: CircularProgressIndicator(color: A2CColors.ink),
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
                    onAction: () => ref.invalidate(sitesListProvider),
                  ),
                ],
                data: (list) => _siteList(context, list, user),
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
        _SiteCard(site: warehouse, featured: true),
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
          _SiteCard(site: site),
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

class _SiteCard extends StatelessWidget {
  const _SiteCard({required this.site, this.featured = false});

  final Site site;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final color = featured ? A2CColors.onInk : A2CColors.ink;
    final secondary = featured
        ? A2CColors.onInkSecondary
        : A2CColors.inkSecondary;
    final background = featured ? A2CColors.ink : A2CColors.surface;
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(A2CRadii.lg),
        side: BorderSide(color: featured ? A2CColors.ink : A2CColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
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
