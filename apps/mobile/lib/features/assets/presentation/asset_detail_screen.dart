import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/theme/a2c_colors.dart';
import '../../../core/theme/a2c_dimens.dart';
import '../../../core/theme/a2c_typography.dart';
import '../../../shared/domain/asset_status.dart';
import '../../../shared/widgets/a2c_cards.dart';
import '../../../shared/widgets/a2c_chips.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/assets_repository.dart';
import '../domain/asset.dart';

class AssetDetailScreen extends ConsumerStatefulWidget {
  const AssetDetailScreen({super.key, required this.assetId});

  final String assetId;

  @override
  ConsumerState<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends ConsumerState<AssetDetailScreen> {
  final _note = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = ref.watch(assetDetailProvider(widget.assetId));
    final notes = ref.watch(assetNotesProvider(widget.assetId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del activo', style: A2CText.title),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
        ),
      ),
      body: asset.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: A2CColors.ink),
        ),
        error: (error, _) => EmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'No se pudo cargar el activo',
          message: error is ApiFailure ? error.message : 'Inténtalo de nuevo.',
          actionLabel: 'Reintentar',
          onAction: () => ref.invalidate(assetDetailProvider(widget.assetId)),
        ),
        data: (value) => _content(value, notes),
      ),
    );
  }

  Widget _content(Asset asset, AsyncValue<List<AssetNote>> notes) => ListView(
    padding: const EdgeInsets.fromLTRB(A2CSpace.screen, 8, A2CSpace.screen, 40),
    children: [
      Text(asset.name, style: A2CText.headline.copyWith(fontSize: 30)),
      const SizedBox(height: 5),
      Text(asset.code, style: A2CText.code.copyWith(fontSize: 16)),
      const SizedBox(height: 12),
      Row(
        children: [
          StatusBadge(status: AssetStatus.fromApi(asset.status)),
          const SizedBox(width: 8),
          Text(
            asset.type == 'MAQUINA' ? 'Máquina' : 'Herramienta',
            style: A2CText.caption,
          ),
        ],
      ),
      const SizedBox(height: 18),
      HighlightCard(
        title: 'Stock total',
        subtitle: 'Distribuido en ${asset.distribution.length} ubicaciones',
        value: '${asset.totalStock}',
        unit: asset.totalStock == 1 ? 'unidad' : 'unidades',
      ),
      if (asset.description?.isNotEmpty ?? false) ...[
        const SizedBox(height: 12),
        A2CCard(child: Text(asset.description!, style: A2CText.body)),
      ],
      const SizedBox(height: 22),
      const Text('Distribución', style: A2CText.title),
      const SizedBox(height: 10),
      if (asset.distribution.isEmpty)
        const EmptyState(
          icon: Icons.location_off_outlined,
          title: 'Sin stock asignado',
          message: 'Este activo no tiene unidades en ninguna ubicación.',
        )
      else
        for (final row in asset.distribution) ...[
          A2CCard(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            child: Row(
              children: [
                Icon(
                  row.siteType == 'ALMACEN'
                      ? Icons.warehouse_outlined
                      : Icons.apartment_rounded,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(row.siteName, style: A2CText.bodyStrong)),
                Text(
                  '×${row.quantity}',
                  style: A2CText.metric.copyWith(fontSize: 21),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      const SizedBox(height: 14),
      const Text('Notas', style: A2CText.title),
      const SizedBox(height: 9),
      TextField(
        controller: _note,
        minLines: 2,
        maxLines: 4,
        maxLength: 1000,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'Agrega un detalle o seguimiento…',
        ),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton.icon(
          onPressed: _saving ? null : () => _addNote(asset),
          icon: _saving
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_rounded, size: 17),
          label: const Text('Agregar nota'),
        ),
      ),
      const SizedBox(height: 7),
      ...notes.when(
        loading: () => [
          const Center(child: CircularProgressIndicator(color: A2CColors.ink)),
        ],
        error: (error, _) => [
          Text(
            error is ApiFailure
                ? error.message
                : 'No se pudieron cargar las notas.',
          ),
        ],
        data: (items) => items.isEmpty
            ? [const Text('Todavía no hay notas.', style: A2CText.caption)]
            : [for (final item in items) _NoteCard(note: item)],
      ),
    ],
  );

  Future<void> _addNote(Asset asset) async {
    final body = _note.text.trim();
    if (body.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe una nota de al menos 2 caracteres.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(assetsRepositoryProvider).addNote(asset.id, body);
      _note.clear();
      ref.invalidate(assetNotesProvider(asset.id));
      ref.invalidate(assetDetailProvider(asset.id));
      ref.invalidate(assetsListProvider);
    } on ApiFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});
  final AssetNote note;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: A2CCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(note.body, style: A2CText.body),
          const SizedBox(height: 7),
          Text(
            '${note.userName} · ${note.createdAt.toLocal().toString().substring(0, 16)}',
            style: A2CText.caption.copyWith(color: A2CColors.inkSecondary),
          ),
        ],
      ),
    ),
  );
}
