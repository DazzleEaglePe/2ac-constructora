import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_failure.dart';
import '../../core/theme/a2c_colors.dart';
import '../../core/theme/a2c_dimens.dart';
import '../../core/theme/a2c_typography.dart';
import '../assets/data/assets_repository.dart';
import '../assets/domain/asset.dart';
import '../auth/application/session_controller.dart';
import '../../shared/domain/asset_status.dart';
import '../../shared/widgets/a2c_cards.dart';
import '../../shared/widgets/a2c_chips.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_skeleton.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _search = TextEditingController();
  Timer? _searchDebounce;
  bool _loadingMore = false;
  String _type = 'TODOS';
  String _status = 'TODOS';

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AssetSearchQuery>(assetSearchQueryProvider, (_, query) {
      if (query.q != _search.text ||
          query.type != (_type == 'TODOS' ? null : _type) ||
          query.status != (_status == 'TODOS' ? null : _status)) {
        _search.value = TextEditingValue(
          text: query.q,
          selection: TextSelection.collapsed(offset: query.q.length),
        );
        setState(() {
          _type = query.type ?? 'TODOS';
          _status = query.status ?? 'TODOS';
        });
      }
    });
    final assets = ref.watch(inventoryAssetsProvider);
    final isAdmin = ref.watch(currentUserProvider)?.isAdmin ?? false;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: A2CColors.ink,
          onRefresh: () => ref.refresh(inventoryAssetsProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              A2CSpace.screen,
              28,
              A2CSpace.screen,
              120,
            ),
            children: [
              Text(
                'Inventario',
                style: A2CText.headline.copyWith(fontSize: 36),
              ),
              const SizedBox(height: 5),
              Text(
                'Herramientas y máquinas registradas',
                style: A2CText.body.copyWith(color: A2CColors.inkSecondary),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _search,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o código',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpiar búsqueda',
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                            _updateQuery();
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              _filters(),
              const SizedBox(height: 16),
              ...assets.when(
                loading: () => [
                  const A2CLoadingSkeleton(
                    label: 'Cargando el inventario',
                    rows: 4,
                  ),
                ],
                error: (error, _) => [
                  EmptyState(
                    icon: Icons.cloud_off_rounded,
                    title: 'No se pudo cargar el inventario',
                    message: error is ApiFailure
                        ? error.message
                        : 'Revisa la conexión e inténtalo de nuevo.',
                    actionLabel: 'Reintentar',
                    onAction: () => ref.invalidate(inventoryAssetsProvider),
                  ),
                ],
                data: _assetRows,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              tooltip: 'Agregar activo',
              backgroundColor: A2CColors.brandYellow,
              foregroundColor: A2CColors.ink,
              onPressed: () => context.push('/inventory/assets/new'),
              child: const Icon(Icons.add_rounded),
            )
          : null,
      floatingActionButtonLocation: const _InventoryFabLocation(),
    );
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), _updateQuery);
  }

  void _updateQuery() => ref
      .read(assetSearchQueryProvider.notifier)
      .update(
        q: _search.text.trim(),
        type: _type == 'TODOS' ? null : _type,
        status: _status == 'TODOS' ? null : _status,
      );

  Widget _filters() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 7,
        children: [
          for (final (key, label) in const [
            ('TODOS', 'Todo'),
            ('MAQUINA', 'Máquinas'),
            ('HERRAMIENTA', 'Herramientas'),
          ])
            ChoiceChip(
              label: Text(label),
              selected: _type == key,
              onSelected: (_) {
                setState(() => _type = key);
                _updateQuery();
              },
              selectedColor: A2CColors.brandYellow,
              showCheckmark: false,
              labelStyle: A2CText.label,
            ),
        ],
      ),
      const SizedBox(height: 5),
      Wrap(
        spacing: 7,
        children: [
          for (final (key, label) in const [
            ('TODOS', 'Todos los estados'),
            ('OPERATIVO', 'Operativo'),
            ('MANTENIMIENTO', 'Mantenimiento'),
            ('BAJA', 'Baja'),
          ])
            ChoiceChip(
              label: Text(label),
              selected: _status == key,
              onSelected: (_) {
                setState(() => _status = key);
                _updateQuery();
              },
              selectedColor: A2CColors.brandYellow,
              showCheckmark: false,
              labelStyle: A2CText.caption,
            ),
        ],
      ),
    ],
  );

  List<Widget> _assetRows(AssetPage page) {
    final assets = page.assets;
    if (assets.isEmpty) {
      final hasFilter =
          _search.text.trim().isNotEmpty ||
          _type != 'TODOS' ||
          _status != 'TODOS';
      return [
        EmptyState(
          icon: Icons.inventory_2_outlined,
          title: hasFilter ? 'Sin resultados' : 'Aún no hay activos',
          message: !hasFilter
              ? 'Las herramientas y máquinas registradas aparecerán aquí con su stock y ubicación.'
              : 'Prueba cambiando la búsqueda o los filtros.',
        ),
      ];
    }
    return [
      Text(
        page.nextCursor == null
            ? '${assets.length} ${assets.length == 1 ? 'activo' : 'activos'}'
            : 'Mostrando ${assets.length} activos',
        style: A2CText.caption,
      ),
      const SizedBox(height: 8),
      for (final asset in assets) ...[
        _AssetRow(asset: asset),
        const SizedBox(height: 9),
      ],
      if (page.nextCursor != null)
        OutlinedButton.icon(
          onPressed: _loadingMore ? null : _loadMore,
          icon: _loadingMore
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    semanticsLabel: 'Cargando más activos',
                  ),
                )
              : const Icon(Icons.expand_more_rounded),
          label: Text(_loadingMore ? 'Cargando…' : 'Cargar más activos'),
        ),
    ];
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      await ref.read(inventoryAssetsProvider.notifier).loadMore();
    } on Object catch (error) {
      if (mounted) {
        final message = error is ApiFailure
            ? error.message
            : 'No se pudieron cargar más activos. Inténtalo de nuevo.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }
}

class _InventoryFabLocation extends FloatingActionButtonLocation {
  const _InventoryFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) =>
      FloatingActionButtonLocation.endFloat
          .getOffset(geometry)
          .translate(0, -A2CSpace.bottomNavClearance);
}

class _AssetRow extends StatelessWidget {
  const _AssetRow({required this.asset});
  final Asset asset;

  @override
  Widget build(BuildContext context) => A2CCard(
    onTap: () => context.push('/inventory/assets/${asset.id}'),
    padding: const EdgeInsets.all(15),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: asset.type == 'MAQUINA'
              ? A2CColors.ink
              : A2CColors.brandYellow,
          foregroundColor: asset.type == 'MAQUINA'
              ? A2CColors.onInk
              : A2CColors.ink,
          child: Icon(
            asset.type == 'MAQUINA'
                ? Icons.precision_manufacturing_outlined
                : Icons.handyman_outlined,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                asset.name,
                style: A2CText.bodyStrong,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(asset.code, style: A2CText.code),
              if (asset.distribution.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (final row in asset.distribution.take(2))
                  Text(
                    '${row.siteName} · ${row.quantity}',
                    style: A2CText.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
              const SizedBox(height: 7),
              StatusBadge(status: AssetStatus.fromApi(asset.status)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${asset.totalStock}',
              style: A2CText.metric.copyWith(fontSize: 25),
            ),
            Text(
              asset.totalStock == 1 ? 'unidad' : 'unidades',
              style: A2CText.caption,
            ),
          ],
        ),
      ],
    ),
  );
}
