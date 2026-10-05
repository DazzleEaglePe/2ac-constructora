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
import '../../movements/data/movements_repository.dart';
import '../../movements/domain/movement.dart';
import '../../../features/auth/application/session_controller.dart';
import '../../sites/data/sites_repository.dart';

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
    final history = ref.watch(assetMovementHistoryProvider(widget.assetId));
    final canResolve = ref.watch(currentUserProvider)?.isAdmin ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del activo', style: A2CText.title),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
        ),
        actions: [
          if (canResolve)
            asset.whenOrNull(
                  data: (value) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Editar activo',
                        onPressed: () => _editAsset(value),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Cambiar estado',
                        initialValue: value.status,
                        onSelected: (status) => _changeStatus(value, status),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'OPERATIVO',
                            child: Text('Marcar operativo'),
                          ),
                          PopupMenuItem(
                            value: 'MANTENIMIENTO',
                            child: Text('Enviar a mantenimiento'),
                          ),
                          PopupMenuItem(
                            value: 'BAJA',
                            child: Text('Dar de baja'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ) ??
                const SizedBox.shrink(),
        ],
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
        data: (value) => _content(value, notes, history, canResolve),
      ),
    );
  }

  Widget _content(
    Asset asset,
    AsyncValue<List<AssetNote>> notes,
    AsyncValue<List<Movement>> history,
    bool canResolve,
  ) => ListView(
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
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: asset.status == 'BAJA'
            ? null
            : () => context.push('/inventory/assets/${asset.id}/move'),
        icon: const Icon(Icons.swap_horiz_rounded),
        label: const Text('Registrar movimiento'),
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
      const Text('Historial de movimientos', style: A2CText.title),
      const SizedBox(height: 9),
      ...history.when(
        loading: () => [
          const Center(child: CircularProgressIndicator(color: A2CColors.ink)),
        ],
        error: (error, _) => [
          Text(
            error is ApiFailure
                ? error.message
                : 'No se pudo cargar el historial.',
          ),
        ],
        data: (items) {
          final reversedIds = items
              .map((item) => item.revertsId)
              .whereType<String>()
              .toSet();
          return items.isEmpty
              ? [
                  const Text(
                    'Todavía no hay movimientos.',
                    style: A2CText.caption,
                  ),
                ]
              : [
                  for (final item in items)
                    _MovementCard(
                      movement: item,
                      canResolve: canResolve,
                      canRevert: canResolve,
                      isReverted: reversedIds.contains(item.id),
                      onResolve: () => _resolveObservation(asset.id, item),
                      onRevert: () => _revertMovement(asset.id, item),
                    ),
                ];
        },
      ),
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

  Future<void> _editAsset(Asset asset) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: asset.name);
    final description = TextEditingController(text: asset.description ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar activo'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                autofocus: true,
                maxLength: 120,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) => value == null || value.trim().length < 2
                    ? 'Ingresa al menos 2 caracteres'
                    : null,
              ),
              TextFormField(
                controller: description,
                maxLength: 2000,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    final updatedName = name.text.trim();
    final updatedDescription = description.text.trim();
    name.dispose();
    description.dispose();
    if (saved != true || !mounted) return;
    try {
      await ref
          .read(assetsRepositoryProvider)
          .update(
            asset.id,
            name: updatedName,
            description: updatedDescription.isEmpty ? null : updatedDescription,
          );
      _refreshAsset(asset.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Activo actualizado.')));
      }
    } on ApiFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _changeStatus(Asset asset, String status) async {
    if (asset.status == status) return;
    final reason = TextEditingController();
    String? validationMessage;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
            status == 'BAJA' ? 'Dar de baja el activo' : 'Cambiar estado',
          ),
          content: status == 'BAJA'
              ? TextField(
                  controller: reason,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Motivo',
                    errorText: validationMessage,
                  ),
                )
              : Text('¿Cambiar el estado a ${_statusLabel(status)}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (status == 'BAJA' && reason.text.trim().length < 3) {
                  setDialogState(
                    () => validationMessage = 'Escribe al menos 3 caracteres',
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
    final reasonText = reason.text.trim();
    reason.dispose();
    if (accepted != true || !mounted) return;
    try {
      await ref
          .read(assetsRepositoryProvider)
          .changeStatus(
            asset.id,
            status: status,
            reason: reasonText.isEmpty ? null : reasonText,
          );
      _refreshAsset(asset.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado actualizado a ${_statusLabel(status)}.'),
          ),
        );
      }
    } on ApiFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  void _refreshAsset(String id) {
    ref.invalidate(assetDetailProvider(id));
    ref.invalidate(assetsListProvider);
  }

  String _statusLabel(String status) => switch (status) {
    'OPERATIVO' => 'Operativo',
    'MANTENIMIENTO' => 'Mantenimiento',
    'BAJA' => 'Baja',
    _ => status,
  };

  Future<void> _resolveObservation(String assetId, Movement movement) async {
    final observation = movement.observation;
    if (observation == null || observation['status'] != 'ABIERTA') return;
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
              if (controller.text.trim().length < 3) return;
              Navigator.pop(context, controller.text.trim());
            },
            child: const Text('Guardar resolución'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (resolution == null || !mounted) return;
    try {
      await ref
          .read(movementsRepositoryProvider)
          .resolveObservation(observation['id'] as String, resolution);
      ref.invalidate(assetMovementHistoryProvider(assetId));
      ref.invalidate(assetDetailProvider(assetId));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Observación atendida.')));
      }
    } on ApiFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _revertMovement(String assetId, Movement movement) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revertir movimiento'),
        content: Text(
          'Se creará un movimiento inverso para devolver ${movement.quantity} ${movement.quantity == 1 ? 'unidad' : 'unidades'} al origen. El historial original se conserva.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revertir'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    try {
      await ref.read(movementsRepositoryProvider).revert(movement.id);
      ref.invalidate(assetMovementHistoryProvider(assetId));
      ref.invalidate(assetDetailProvider(assetId));
      ref.invalidate(assetsListProvider);
      ref.invalidate(sitesListProvider);
      if (movement.from != null) {
        ref.invalidate(siteDetailProvider(movement.from!.id));
        ref.invalidate(siteStockProvider(movement.from!.id));
        ref.invalidate(siteMovementHistoryProvider(movement.from!.id));
      }
      if (movement.to != null) {
        ref.invalidate(siteDetailProvider(movement.to!.id));
        ref.invalidate(siteStockProvider(movement.to!.id));
        ref.invalidate(siteMovementHistoryProvider(movement.to!.id));
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Movimiento revertido.')));
      }
    } on ApiFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
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

class _MovementCard extends StatelessWidget {
  const _MovementCard({
    required this.movement,
    required this.canResolve,
    required this.canRevert,
    required this.isReverted,
    required this.onResolve,
    required this.onRevert,
  });
  final Movement movement;
  final bool canResolve;
  final bool canRevert;
  final bool isReverted;
  final VoidCallback onResolve;
  final VoidCallback onRevert;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: A2CCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${movement.from?.name ?? 'Ingreso'} → ${movement.to?.name ?? 'Salida'}',
            style: A2CText.bodyStrong,
          ),
          const SizedBox(height: 4),
          Text(
            '${movement.quantity} ${movement.quantity == 1 ? 'unidad' : 'unidades'} · ${movement.userName}',
            style: A2CText.caption,
          ),
          const SizedBox(height: 3),
          Text(
            movement.createdAt.toLocal().toString().substring(0, 16),
            style: A2CText.caption.copyWith(color: A2CColors.inkSecondary),
          ),
          if (movement.note?.isNotEmpty ?? false) ...[
            const SizedBox(height: 7),
            Text(movement.note!, style: A2CText.body),
          ],
          if (movement.observation != null) ...[
            const SizedBox(height: 7),
            Text(
              'Observación ${movement.observation!['type']}: ${movement.observation!['description']} · ${movement.observation!['status']}',
              style: A2CText.caption.copyWith(color: A2CColors.goldText),
            ),
            if (canResolve && movement.observation!['status'] == 'ABIERTA') ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onResolve,
                  icon: const Icon(Icons.task_alt_rounded, size: 18),
                  label: const Text('Marcar atendida'),
                ),
              ),
            ],
          ],
          if (canRevert && movement.kind == 'TRASLADO' && !isReverted) ...[
            const SizedBox(height: 3),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRevert,
                icon: const Icon(Icons.undo_rounded, size: 18),
                label: const Text('Revertir movimiento'),
              ),
            ),
          ],
          if (isReverted)
            Text(
              'Movimiento revertido',
              style: A2CText.caption.copyWith(color: A2CColors.inkSecondary),
            ),
        ],
      ),
    ),
  );
}
