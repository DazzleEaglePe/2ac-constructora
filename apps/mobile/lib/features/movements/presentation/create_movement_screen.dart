import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/theme/a2c_colors.dart';
import '../../../core/theme/a2c_dimens.dart';
import '../../../core/theme/a2c_typography.dart';
import '../../../core/storage/offline_movements.dart';
import '../../../features/assets/data/assets_repository.dart';
import '../../../features/assets/domain/asset.dart';
import '../../../features/auth/application/session_controller.dart';
import '../../../features/sites/data/sites_repository.dart';
import '../../../features/sites/domain/site.dart';
import '../../../shared/widgets/a2c_buttons.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../data/movements_repository.dart';

class CreateMovementScreen extends ConsumerStatefulWidget {
  const CreateMovementScreen({
    super.key,
    required this.assetId,
    this.initialFromSiteId,
    this.initialToSiteId,
  });

  final String assetId;
  final String? initialFromSiteId;
  final String? initialToSiteId;

  @override
  ConsumerState<CreateMovementScreen> createState() =>
      _CreateMovementScreenState();
}

class _CreateMovementScreenState extends ConsumerState<CreateMovementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController(text: '1');
  final _note = TextEditingController();
  final _observationDescription = TextEditingController();
  String? _fromSiteId;
  String? _toSiteId;
  bool _reportObservation = false;
  String _observationType = 'DANADO';
  bool _sending = false;
  ApiFailure? _error;

  @override
  void dispose() {
    _quantity.dispose();
    _note.dispose();
    _observationDescription.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = ref.watch(assetDetailProvider(widget.assetId));
    final sites = ref.watch(sitesListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar movimiento', style: A2CText.title),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
        ),
      ),
      body: asset.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(A2CSpace.screen),
          children: [
            const A2CLoadingSkeleton(
              label: 'Cargando los datos del movimiento',
            ),
          ],
        ),
        error: (error, _) => EmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'No se pudo cargar el activo',
          message: error is ApiFailure ? error.message : 'Inténtalo de nuevo.',
          actionLabel: 'Reintentar',
          onAction: () => ref.invalidate(assetDetailProvider(widget.assetId)),
        ),
        data: (value) => sites.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(A2CSpace.screen),
            children: [
              const A2CLoadingSkeleton(label: 'Cargando las ubicaciones'),
            ],
          ),
          error: (error, _) => EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'No se pudieron cargar las ubicaciones',
            message: error is ApiFailure
                ? error.message
                : 'Inténtalo de nuevo.',
            actionLabel: 'Reintentar',
            onAction: () => ref.invalidate(sitesListProvider),
          ),
          data: (locations) => _form(value, locations),
        ),
      ),
    );
  }

  Widget _form(Asset asset, List<Site> sites) {
    final activeSites = sites
        .where((site) => !site.isClosed)
        .toList(growable: false);
    final available = asset.distribution
        .where((row) => row.quantity > 0)
        .toList(growable: false);
    if (_fromSiteId == null ||
        !available.any((row) => row.siteId == _fromSiteId)) {
      _fromSiteId =
          available.any((row) => row.siteId == widget.initialFromSiteId)
          ? widget.initialFromSiteId
          : available.firstOrNull?.siteId;
    }
    if (_toSiteId == null ||
        !activeSites.any((site) => site.id == _toSiteId) ||
        _toSiteId == _fromSiteId) {
      _toSiteId =
          activeSites.any(
            (site) =>
                site.id == widget.initialToSiteId && site.id != _fromSiteId,
          )
          ? widget.initialToSiteId
          : activeSites.where((site) => site.id != _fromSiteId).firstOrNull?.id;
    }
    final availableQuantity =
        available
            .where((row) => row.siteId == _fromSiteId)
            .firstOrNull
            ?.quantity ??
        0;
    final destination = activeSites
        .where((site) => site.id == _toSiteId)
        .firstOrNull;

    if (asset.status == 'BAJA') {
      return const EmptyState(
        icon: Icons.block_rounded,
        title: 'Activo dado de baja',
        message: 'Un activo dado de baja no se puede trasladar.',
      );
    }
    if (available.isEmpty || activeSites.length < 2) {
      return const EmptyState(
        icon: Icons.swap_horiz_rounded,
        title: 'No hay un movimiento disponible',
        message:
            'El activo necesita stock y debe existir otra ubicación activa.',
      );
    }
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          A2CSpace.screen,
          8,
          A2CSpace.screen,
          32,
        ),
        children: [
          Text(asset.name, style: A2CText.headline.copyWith(fontSize: 28)),
          const SizedBox(height: 4),
          Text(
            '${asset.code} · ${asset.status == 'MANTENIMIENTO' ? 'En mantenimiento' : 'Operativo'}',
            style: A2CText.code,
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _fromSiteId,
            decoration: const InputDecoration(
              labelText: 'Origen',
              hintText: 'Selecciona la ubicación de origen',
            ),
            items: [
              for (final row in available)
                DropdownMenuItem(
                  value: row.siteId,
                  child: Text(
                    '${row.siteName} · ${row.quantity} disponibles',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) => setState(() {
              _fromSiteId = value;
              if (_toSiteId == value) _toSiteId = null;
              _error = null;
            }),
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            initialValue: _toSiteId,
            decoration: const InputDecoration(
              labelText: 'Destino',
              hintText: 'Selecciona el destino',
            ),
            items: [
              for (final site in activeSites.where(
                (site) => site.id != _fromSiteId,
              ))
                DropdownMenuItem(
                  value: site.id,
                  child: Text(site.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            validator: (value) =>
                value == null ? 'Selecciona un destino' : null,
            onChanged: (value) => setState(() {
              _toSiteId = value;
              _error = null;
            }),
          ),
          if (asset.type == 'HERRAMIENTA') ...[
            const SizedBox(height: 15),
            TextFormField(
              controller: _quantity,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Cantidad',
                hintText: '1 a $availableQuantity',
              ),
              validator: (value) {
                final count = int.tryParse(value ?? '');
                return count == null || count < 1 || count > availableQuantity
                    ? 'Indica una cantidad entre 1 y $availableQuantity'
                    : null;
              },
            ),
          ] else ...[
            const SizedBox(height: 14),
            Text(
              'Las máquinas se trasladan de una en una.',
              style: A2CText.caption.copyWith(color: A2CColors.inkSecondary),
            ),
          ],
          const SizedBox(height: 15),
          TextField(
            controller: _note,
            minLines: 1,
            maxLines: 3,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nota (opcional)',
              hintText: 'Ej. Sale con accesorios completos',
            ),
          ),
          const SizedBox(height: 5),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _reportObservation,
            onChanged: (value) =>
                setState(() => _reportObservation = value ?? false),
            title: const Text('Reportar una observación'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (_reportObservation) ...[
            DropdownButtonFormField<String>(
              initialValue: _observationType,
              decoration: const InputDecoration(
                labelText: 'Tipo de observación',
              ),
              items: const [
                DropdownMenuItem(value: 'DANADO', child: Text('Dañado')),
                DropdownMenuItem(
                  value: 'INCOMPLETO',
                  child: Text('Incompleto'),
                ),
                DropdownMenuItem(value: 'FALTANTE', child: Text('Faltante')),
                DropdownMenuItem(value: 'OTRO', child: Text('Otro')),
              ],
              onChanged: (value) => setState(() {
                if (value != null) _observationType = value;
              }),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _observationDescription,
              minLines: 2,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descripción de la observación',
                hintText: 'Describe lo observado',
              ),
              validator: (value) =>
                  _reportObservation && (value?.trim().length ?? 0) < 3
                  ? 'Describe la observación con al menos 3 caracteres'
                  : null,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Semantics(
              container: true,
              liveRegion: true,
              label: _error!.message,
              child: ExcludeSemantics(
                child: Text(
                  _error!.message,
                  style: const TextStyle(color: A2CColors.error),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          A2CPrimaryButton(
            label: 'Continuar',
            icon: Icons.arrow_forward_rounded,
            loading: _sending,
            loadingLabel: 'Registrando movimiento',
            onPressed: () => _confirm(asset, sites, destination),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(
    Asset asset,
    List<Site> sites,
    Site? destination,
  ) async {
    if (!_formKey.currentState!.validate()) return;
    final source = sites.where((site) => site.id == _fromSiteId).firstOrNull;
    if (source == null || destination == null) return;
    final quantity = asset.type == 'MAQUINA' ? 1 : int.parse(_quantity.text);
    final currentUser = ref.read(currentUserProvider)?.fullName ?? 'tu usuario';
    final maintenanceWarning =
        asset.status == 'MANTENIMIENTO' && destination.type == 'OBRA';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirma el movimiento'),
        content: Text(
          '${maintenanceWarning ? 'Aviso: el activo está en mantenimiento. El traslado se permite.\n\n' : ''}'
          'Mover $quantity ${quantity == 1 ? 'unidad' : 'unidades'} de ${asset.name} de ${source.name} a ${destination.name}.\n\n'
          'Quedará registrado a nombre de $currentUser.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar movimiento'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final idempotencyKey = newIdempotencyKey();
    final payload = <String, Object?>{
      'assetId': asset.id,
      'assetName': asset.name,
      'assetCode': asset.code,
      'fromSiteId': _fromSiteId!,
      'toSiteId': _toSiteId!,
      'quantity': quantity,
      'note': _note.text,
      'observationType': _reportObservation ? _observationType : null,
      'observationDescription': _reportObservation
          ? _observationDescription.text
          : null,
    };
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(movementsRepositoryProvider)
          .transfer(
            assetId: asset.id,
            fromSiteId: _fromSiteId!,
            toSiteId: _toSiteId!,
            quantity: quantity,
            note: _note.text,
            observationType: _reportObservation ? _observationType : null,
            observationDescription: _reportObservation
                ? _observationDescription.text
                : null,
            idempotencyKey: idempotencyKey,
          );
      invalidateWidgetAssetCatalog(ref);
      ref.invalidate(assetDetailProvider(asset.id));
      ref.invalidate(assetMovementHistoryProvider(asset.id));
      ref.invalidate(sitesListProvider);
      ref.invalidate(siteDetailProvider(_fromSiteId!));
      ref.invalidate(siteDetailProvider(_toSiteId!));
      ref.invalidate(siteStockProvider(_fromSiteId!));
      ref.invalidate(siteStockProvider(_toSiteId!));
      ref.invalidate(siteMovementHistoryProvider(_fromSiteId!));
      ref.invalidate(siteMovementHistoryProvider(_toSiteId!));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Movimiento registrado.')));
        context.pop(true);
      }
    } on ApiFailure catch (error) {
      if (error.code == ApiFailure.offline.code) {
        final userId = ref.read(currentUserProvider)?.id;
        if (userId != null) {
          await ref
              .read(offlineMovementQueueProvider)
              .enqueue(
                ownerId: userId,
                payload: payload,
                idempotencyKey: idempotencyKey,
              );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sin conexión. El movimiento quedó pendiente.'),
              ),
            );
            context.pop(true);
          }
          return;
        }
      }
      if (error.code == 'STOCK_INSUFICIENTE') {
        ref.invalidate(assetDetailProvider(widget.assetId));
      }
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
