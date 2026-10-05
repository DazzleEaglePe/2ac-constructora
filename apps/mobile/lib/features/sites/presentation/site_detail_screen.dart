import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/theme/a2c_colors.dart';
import '../../../core/theme/a2c_dimens.dart';
import '../../../core/theme/a2c_typography.dart';
import '../../../shared/domain/asset_status.dart';
import '../../../shared/widgets/a2c_buttons.dart';
import '../../../shared/widgets/a2c_cards.dart';
import '../../../shared/widgets/a2c_chips.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../auth/application/session_controller.dart';
import '../data/sites_repository.dart';
import '../domain/site.dart';
import 'maps_launcher.dart';

class SiteDetailScreen extends ConsumerStatefulWidget {
  const SiteDetailScreen({super.key, required this.siteId});

  final String siteId;

  @override
  ConsumerState<SiteDetailScreen> createState() => _SiteDetailScreenState();
}

class _SiteDetailScreenState extends ConsumerState<SiteDetailScreen> {
  String _filter = 'TODOS';
  bool _changingStatus = false;

  @override
  Widget build(BuildContext context) {
    final site = ref.watch(siteDetailProvider(widget.siteId));
    final stock = ref.watch(siteStockProvider(widget.siteId));
    final canManage = ref.watch(currentUserProvider)?.isAdmin ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de ubicación', style: A2CText.title),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
        ),
        actions: [
          site.whenOrNull(
                data: (value) => canManage && !value.isWarehouse
                    ? IconButton(
                        tooltip: 'Editar obra',
                        onPressed: () => context.push(
                          '/sites/${value.id}/edit',
                          extra: value,
                        ),
                        icon: const Icon(Icons.edit_outlined),
                      )
                    : null,
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: site.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: A2CColors.ink),
        ),
        error: (error, _) => EmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'No se pudo cargar la ubicación',
          message: error is ApiFailure ? error.message : 'Inténtalo de nuevo.',
          actionLabel: 'Reintentar',
          onAction: () => ref.invalidate(siteDetailProvider(widget.siteId)),
        ),
        data: (value) => _buildDetail(context, value, stock, canManage),
      ),
    );
  }

  Widget _buildDetail(
    BuildContext context,
    Site site,
    AsyncValue<List<SiteStockItem>> stock,
    bool canManage,
  ) => ListView(
    padding: const EdgeInsets.fromLTRB(A2CSpace.screen, 8, A2CSpace.screen, 32),
    children: [
      Text(
        site.name,
        style: A2CText.headline.copyWith(fontSize: 31),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          _LocationTag(label: site.isWarehouse ? 'Almacén central' : 'Obra'),
          const SizedBox(width: 8),
          _LocationTag(
            label: site.isClosed ? 'Cerrada' : 'Activa',
            closed: site.isClosed,
          ),
        ],
      ),
      const SizedBox(height: 20),
      HighlightCard(
        title: site.isWarehouse ? 'Stock en almacén' : 'Stock en obra',
        subtitle: '${site.summary.assetCount} tipos de activo',
        value: '${site.summary.units}',
        unit: site.summary.units == 1 ? 'unidad' : 'unidades',
      ),
      if (site.ownerName != null ||
          site.address != null ||
          (site.lat != null && site.lng != null)) ...[
        const SizedBox(height: 12),
        A2CCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (site.ownerName != null) ...[
                const Text('RESPONSABLE', style: A2CText.overline),
                const SizedBox(height: 5),
                Text(site.ownerName!, style: A2CText.bodyStrong),
              ],
              if (site.address != null && site.address!.isNotEmpty) ...[
                if (site.ownerName != null) const SizedBox(height: 14),
                const Text('DIRECCIÓN', style: A2CText.overline),
                const SizedBox(height: 5),
                Text(site.address!, style: A2CText.body),
              ],
              if (site.lat != null && site.lng != null) ...[
                const SizedBox(height: 8),
                Text('${site.lat}, ${site.lng}', style: A2CText.code),
              ],
              if ((site.address?.isNotEmpty ?? false) ||
                  (site.lat != null && site.lng != null)) ...[
                const SizedBox(height: 12),
                A2CSecondaryButton(
                  label: 'Abrir en Maps',
                  icon: Icons.map_outlined,
                  onPressed: () => _openMaps(site),
                ),
              ],
            ],
          ),
        ),
      ],
      if (canManage && !site.isWarehouse) ...[
        const SizedBox(height: 12),
        A2CSecondaryButton(
          label: _changingStatus
              ? 'Actualizando…'
              : (site.isClosed ? 'Reabrir obra' : 'Cerrar obra'),
          icon: site.isClosed
              ? Icons.lock_open_rounded
              : Icons.lock_outline_rounded,
          onPressed: _changingStatus ? null : () => _changeStatus(site),
        ),
      ],
      const SizedBox(height: 24),
      const Text('Activos en esta ubicación', style: A2CText.title),
      const SizedBox(height: 12),
      Wrap(
        spacing: 7,
        children: [
          for (final (key, label) in const [
            ('TODOS', 'Todos'),
            ('MAQUINA', 'Máquinas'),
            ('HERRAMIENTA', 'Herramientas'),
          ])
            ChoiceChip(
              label: Text(label),
              selected: _filter == key,
              onSelected: (_) => setState(() => _filter = key),
              selectedColor: A2CColors.brandYellow,
              showCheckmark: false,
              labelStyle: A2CText.label,
            ),
        ],
      ),
      const SizedBox(height: 10),
      ...stock.when(
        loading: () => [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(color: A2CColors.ink),
            ),
          ),
        ],
        error: (error, _) => [
          EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'No se pudo cargar el stock',
            message: error is ApiFailure
                ? error.message
                : 'Inténtalo de nuevo.',
            actionLabel: 'Reintentar',
            onAction: () => ref.invalidate(siteStockProvider(widget.siteId)),
          ),
        ],
        data: (items) {
          final filtered = items
              .where((item) => _filter == 'TODOS' || item.type == _filter)
              .toList(growable: false);
          return filtered.isEmpty
              ? [
                  const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Aún no hay activos',
                    message: 'El stock disponible aparecerá aquí.',
                  ),
                ]
              : [for (final item in filtered) _AssetStockRow(item: item)];
        },
      ),
    ],
  );

  Future<void> _openMaps(Site site) async {
    final opened = await openSiteInMaps(
      address: site.address,
      lat: site.lat,
      lng: site.lng,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No se pudo abrir Maps.')));
    }
  }

  Future<void> _changeStatus(Site site) async {
    final close = !site.isClosed;
    if (close && site.summary.units > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Traslada todo el stock antes de cerrar la obra.'),
        ),
      );
      return;
    }
    if (close) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cerrar obra'),
          content: Text(
            '¿Quieres cerrar ${site.name}? Puedes reabrirla después.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cerrar obra'),
            ),
          ],
        ),
      );
      if (accepted != true || !mounted) return;
    }
    setState(() => _changingStatus = true);
    try {
      final repository = ref.read(sitesRepositoryProvider);
      if (close) {
        await repository.close(site.id);
      } else {
        await repository.reopen(site.id);
      }
      ref.invalidate(siteDetailProvider(site.id));
      ref.invalidate(sitesListProvider);
    } on ApiFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _changingStatus = false);
    }
  }
}

class _LocationTag extends StatelessWidget {
  const _LocationTag({required this.label, this.closed = false});

  final String label;
  final bool closed;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: ShapeDecoration(
      color: closed ? A2CColors.surfaceStrong : A2CColors.brandYellowSoft,
      shape: const StadiumBorder(),
    ),
    child: Text(label, style: A2CText.caption.copyWith(color: A2CColors.ink)),
  );
}

class _AssetStockRow extends StatelessWidget {
  const _AssetStockRow({required this.item});

  final SiteStockItem item;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: A2CCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: item.type == 'MAQUINA'
                ? A2CColors.ink
                : A2CColors.brandYellow,
            foregroundColor: item.type == 'MAQUINA'
                ? A2CColors.onInk
                : A2CColors.ink,
            child: Icon(
              item.type == 'MAQUINA'
                  ? Icons.precision_manufacturing_outlined
                  : Icons.handyman_outlined,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: A2CText.bodyStrong),
                Text(item.code, style: A2CText.code),
                const SizedBox(height: 5),
                StatusBadge(status: AssetStatus.fromApi(item.status)),
              ],
            ),
          ),
          Text(
            '×${item.quantity}',
            style: A2CText.metric.copyWith(fontSize: 22),
          ),
        ],
      ),
    ),
  );
}
