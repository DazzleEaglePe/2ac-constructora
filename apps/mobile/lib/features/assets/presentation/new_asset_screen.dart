import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/theme/a2c_colors.dart';
import '../../../core/theme/a2c_dimens.dart';
import '../../../core/theme/a2c_typography.dart';
import '../../../shared/widgets/a2c_buttons.dart';
import '../../sites/data/sites_repository.dart';
import '../../sites/domain/site.dart';
import '../data/assets_repository.dart';

class NewAssetScreen extends ConsumerStatefulWidget {
  const NewAssetScreen({super.key});

  @override
  ConsumerState<NewAssetScreen> createState() => _NewAssetScreenState();
}

class _NewAssetScreenState extends ConsumerState<NewAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  String _type = 'HERRAMIENTA';
  String? _siteId;
  bool _saving = false;
  ApiFailure? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_siteId == null) {
      setState(
        () => _error = const ApiFailure(
          code: 'VALIDACION',
          message: 'Selecciona la ubicación inicial.',
        ),
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(assetsRepositoryProvider)
          .create(
            type: _type,
            name: _name.text.trim(),
            description: _description.text.trim().isEmpty
                ? null
                : _description.text.trim(),
            initialQuantity: _type == 'MAQUINA' ? 1 : int.parse(_quantity.text),
            initialSiteId: _siteId!,
          );
      ref.invalidate(assetsListProvider);
      ref.invalidate(sitesListProvider);
      if (mounted) context.pop(true);
    } on ApiFailure catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sites = ref.watch(sitesListProvider);
    final code = ref.watch(nextAssetCodeProvider(_type));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo activo', style: A2CText.title),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              A2CSpace.screen,
              8,
              A2CSpace.screen,
              32,
            ),
            children: [
              Text(
                'Registra una herramienta o máquina',
                style: A2CText.headline.copyWith(fontSize: 29),
              ),
              const SizedBox(height: 8),
              Text(
                'El código se asigna automáticamente y el stock inicial queda en la ubicación que elijas.',
                style: A2CText.body.copyWith(color: A2CColors.inkSecondary),
              ),
              const SizedBox(height: 22),
              const Text('TIPO', style: A2CText.overline),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'HERRAMIENTA',
                    label: Text('Herramienta'),
                    icon: Icon(Icons.handyman_outlined),
                  ),
                  ButtonSegment(
                    value: 'MAQUINA',
                    label: Text('Máquina'),
                    icon: Icon(Icons.precision_manufacturing_outlined),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (value) => setState(() {
                  _type = value.first;
                  _quantity.text = '1';
                }),
                showSelectedIcon: false,
              ),
              const SizedBox(height: 18),
              const Text('CÓDIGO', style: A2CText.overline),
              const SizedBox(height: 7),
              code.when(
                loading: () =>
                    const LinearProgressIndicator(color: A2CColors.ink),
                error: (_, _) =>
                    const Text('No se pudo consultar el código siguiente'),
                data: (value) =>
                    Text(value, style: A2CText.code.copyWith(fontSize: 17)),
              ),
              const SizedBox(height: 18),
              const Text('NOMBRE', style: A2CText.overline),
              const SizedBox(height: 7),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Ej. Amoladora angular 4½"',
                ),
                validator: (value) => value == null || value.trim().length < 2
                    ? 'Ingresa un nombre de al menos 2 caracteres'
                    : null,
              ),
              const SizedBox(height: 16),
              const Text('DESCRIPCIÓN', style: A2CText.overline),
              const SizedBox(height: 7),
              TextFormField(
                controller: _description,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Marca, modelo, capacidad u otros detalles',
                ),
              ),
              if (_type == 'HERRAMIENTA') ...[
                const SizedBox(height: 16),
                const Text('STOCK INICIAL', style: A2CText.overline),
                const SizedBox(height: 7),
                TextFormField(
                  controller: _quantity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Cantidad de unidades',
                  ),
                  validator: (value) {
                    final quantity = int.tryParse(value ?? '');
                    return quantity == null || quantity < 1
                        ? 'Ingresa una cantidad de al menos 1'
                        : null;
                  },
                ),
              ] else ...[
                const SizedBox(height: 14),
                Text(
                  'Las máquinas se registran de una en una.',
                  style: A2CText.caption.copyWith(
                    color: A2CColors.inkSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text('UBICACIÓN INICIAL', style: A2CText.overline),
              const SizedBox(height: 7),
              sites.when(
                loading: () =>
                    const LinearProgressIndicator(color: A2CColors.ink),
                error: (error, _) => Text(
                  error is ApiFailure
                      ? error.message
                      : 'No se pudieron cargar las ubicaciones',
                ),
                data: (list) => _sitePicker(list),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!.message,
                  style: const TextStyle(color: A2CColors.error),
                ),
              ],
              const SizedBox(height: 28),
              A2CPrimaryButton(
                label: 'Guardar activo',
                icon: Icons.add_rounded,
                loading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sitePicker(List<Site> sites) {
    final active = sites
        .where((site) => !site.isClosed)
        .toList(growable: false);
    if (_siteId != null && !active.any((site) => site.id == _siteId)) {
      _siteId = null;
    }
    return DropdownButtonFormField<String>(
      initialValue: _siteId,
      decoration: const InputDecoration(
        hintText: 'Selecciona una obra o almacén',
      ),
      items: [
        for (final site in active)
          DropdownMenuItem(
            value: site.id,
            child: Text(site.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (value) => setState(() {
        _siteId = value;
        _error = null;
      }),
    );
  }
}
