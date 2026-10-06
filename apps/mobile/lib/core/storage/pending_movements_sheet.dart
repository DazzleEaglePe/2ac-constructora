import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_skeleton.dart';
import 'local_database.dart';
import 'offline_movements.dart';

class PendingMovementsSheet extends ConsumerWidget {
  const PendingMovementsSheet({super.key, required this.ownerId});

  final String ownerId;

  Future<void> _editRejected(
    BuildContext context,
    WidgetRef ref,
    PendingMovement item,
  ) async {
    try {
      final payload = jsonDecode(item.payload) as Map<String, dynamic>;
      final cachedSites = await ref
          .read(localDatabaseProvider)
          .getCache('sites:list');
      if (!context.mounted) return;
      final sites = cachedSites is List
          ? cachedSites.whereType<Map<String, dynamic>>().toList()
          : const <Map<String, dynamic>>[];
      final siteOptions = sites
          .where((site) => site['id'] is String && site['name'] is String)
          .toList();
      final quantityController = TextEditingController(
        text: '${payload['quantity'] ?? 1}',
      );
      final noteController = TextEditingController(
        text: payload['note'] as String? ?? '',
      );
      var fromSiteId = payload['fromSiteId'] as String?;
      var toSiteId = payload['toSiteId'] as String?;
      String? validationError;
      final corrected = await showDialog<Map<String, Object?>>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Corregir movimiento'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (siteOptions.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      initialValue:
                          siteOptions.any((site) => site['id'] == fromSiteId)
                          ? fromSiteId
                          : null,
                      decoration: const InputDecoration(labelText: 'Origen'),
                      items: [
                        for (final site in siteOptions)
                          DropdownMenuItem(
                            value: site['id'] as String,
                            child: Text(site['name'] as String),
                          ),
                      ],
                      onChanged: (value) => setDialogState(() {
                        fromSiteId = value;
                        validationError = null;
                      }),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue:
                          siteOptions.any((site) => site['id'] == toSiteId)
                          ? toSiteId
                          : null,
                      decoration: const InputDecoration(labelText: 'Destino'),
                      items: [
                        for (final site in siteOptions)
                          DropdownMenuItem(
                            value: site['id'] as String,
                            child: Text(site['name'] as String),
                          ),
                      ],
                      onChanged: (value) => setDialogState(() {
                        toSiteId = value;
                        validationError = null;
                      }),
                    ),
                  ] else ...[
                    const Text(
                      'No hay ubicaciones guardadas. Puedes conservar o '
                      'editar los identificadores del movimiento.',
                    ),
                    TextFormField(
                      initialValue: fromSiteId,
                      decoration: const InputDecoration(
                        labelText: 'ID de origen',
                      ),
                      onChanged: (value) => setDialogState(() {
                        fromSiteId = value;
                        validationError = null;
                      }),
                    ),
                    TextFormField(
                      initialValue: toSiteId,
                      decoration: const InputDecoration(
                        labelText: 'ID de destino',
                      ),
                      onChanged: (value) => setDialogState(() {
                        toSiteId = value;
                        validationError = null;
                      }),
                    ),
                  ],
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Cantidad'),
                    onChanged: (_) =>
                        setDialogState(() => validationError = null),
                  ),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: 'Nota'),
                  ),
                  if (validationError != null) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      container: true,
                      liveRegion: true,
                      label: validationError!,
                      child: ExcludeSemantics(
                        child: Text(
                          validationError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  ],
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
                  final quantity = int.tryParse(quantityController.text);
                  if (fromSiteId == null || fromSiteId!.trim().isEmpty) {
                    setDialogState(
                      () => validationError = 'Selecciona un origen.',
                    );
                    return;
                  }
                  if (toSiteId == null || toSiteId!.trim().isEmpty) {
                    setDialogState(
                      () => validationError = 'Selecciona un destino.',
                    );
                    return;
                  }
                  if (fromSiteId == toSiteId) {
                    setDialogState(
                      () => validationError =
                          'El origen y el destino deben ser distintos.',
                    );
                    return;
                  }
                  if (quantity == null || quantity < 1) {
                    setDialogState(
                      () => validationError = 'La cantidad debe ser mayor a 0.',
                    );
                    return;
                  }
                  Navigator.pop(dialogContext, {
                    ...payload,
                    'fromSiteId': fromSiteId!,
                    'toSiteId': toSiteId!,
                    'quantity': quantity,
                    'note': noteController.text,
                  });
                },
                child: const Text('Guardar y reintentar'),
              ),
            ],
          ),
        ),
      );
      quantityController.dispose();
      noteController.dispose();
      if (corrected == null || !context.mounted) return;
      final queue = ref.read(offlineMovementQueueProvider);
      await queue.correctRejected(item.id, corrected);
      await queue.sync(ownerId);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo preparar el movimiento para corregir.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(pendingMovementsProvider(ownerId));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Movimientos pendientes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            rows.when(
              loading: () => const A2CLoadingRows(
                label: 'Cargando movimientos pendientes',
                rows: 2,
              ),
              error: (_, _) => EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'No se pudo leer la cola local',
                message: 'Vuelve a intentarlo para consultar los movimientos.',
                actionLabel: 'Reintentar',
                onAction: () =>
                    ref.invalidate(pendingMovementsProvider(ownerId)),
              ),
              data: (items) {
                final visible = items
                    .where((item) => item.status != 'ENVIADO')
                    .toList();
                if (visible.isEmpty) {
                  return const EmptyState(
                    icon: Icons.cloud_done_outlined,
                    title: 'Todo sincronizado',
                    message: 'No hay movimientos pendientes.',
                  );
                }
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * .55,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = visible[index];
                      final payload =
                          jsonDecode(item.payload) as Map<String, dynamic>;
                      final assetName = payload['assetName'] as String?;
                      final assetCode = payload['assetCode'] as String?;
                      final assetLabel =
                          (assetName == null || assetName.isEmpty)
                          ? (payload['assetId'] as String? ?? 'Activo')
                          : '$assetName${assetCode == null ? '' : ' · $assetCode'}';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${payload['quantity']} unidad(es) · $assetLabel',
                        ),
                        subtitle: Text(
                          item.status == 'RECHAZADO'
                              ? 'Rechazado: ${item.error ?? 'Revisa los datos.'}'
                              : 'Se enviará automáticamente al recuperar la conexión.',
                        ),
                        trailing: item.status == 'RECHAZADO'
                            ? TextButton(
                                onPressed: () =>
                                    _editRejected(context, ref, item),
                                child: const Text('Corregir'),
                              )
                            : const Icon(Icons.schedule_rounded),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
