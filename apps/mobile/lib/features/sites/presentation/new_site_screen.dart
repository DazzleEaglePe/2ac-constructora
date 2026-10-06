import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/theme/a2c_colors.dart';
import '../../../core/theme/a2c_dimens.dart';
import '../../../core/theme/a2c_typography.dart';
import '../../../shared/widgets/a2c_buttons.dart';
import '../data/sites_repository.dart';
import '../domain/site.dart';
import 'maps_launcher.dart';
import 'site_location_picker.dart';

class NewSiteScreen extends ConsumerStatefulWidget {
  const NewSiteScreen({super.key, this.initialSite});

  final Site? initialSite;

  @override
  ConsumerState<NewSiteScreen> createState() => _NewSiteScreenState();
}

class _NewSiteScreenState extends ConsumerState<NewSiteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _owner = TextEditingController();
  final _address = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  bool _saving = false;
  ApiFailure? _error;

  @override
  void dispose() {
    _name.dispose();
    _owner.dispose();
    _address.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final site = widget.initialSite;
    if (site != null) {
      _name.text = site.name;
      _owner.text = site.ownerName ?? '';
      _address.text = site.address ?? '';
      _lat.text = site.lat?.toString() ?? '';
      _lng.text = site.lng?.toString() ?? '';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_lng.text.trim());
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(sitesRepositoryProvider);
      final site = widget.initialSite == null
          ? await repo.create(
              name: _name.text.trim(),
              ownerName: _owner.text.trim(),
              address: _address.text.trim().isEmpty
                  ? null
                  : _address.text.trim(),
              lat: lat,
              lng: lng,
            )
          : await repo.update(
              id: widget.initialSite!.id,
              name: _name.text.trim(),
              ownerName: _owner.text.trim(),
              address: _address.text.trim().isEmpty
                  ? null
                  : _address.text.trim(),
              lat: lat,
              lng: lng,
            );
      ref.invalidate(sitesListProvider);
      ref.invalidate(siteDetailProvider(site.id));
      if (mounted) context.go('/sites/${site.id}');
    } on ApiFailure catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickLocation() async {
    final latitude = double.tryParse(_lat.text.trim());
    final longitude = double.tryParse(_lng.text.trim());
    final selected = await showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SiteLocationPicker(
        initialPosition: latitude != null && longitude != null
            ? LatLng(latitude, longitude)
            : null,
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _lat.text = selected.latitude.toStringAsFixed(6);
      _lng.text = selected.longitude.toStringAsFixed(6);
    });
    if (kIsWeb || _address.text.trim().isNotEmpty) return;
    try {
      final placemarks = await Geocoding(locale: const Locale('es', 'PE'))
          .placemarkFromCoordinates(selected.latitude, selected.longitude);
      if (!mounted || _address.text.trim().isNotEmpty || placemarks.isEmpty) {
        return;
      }
      final place = placemarks.first;
      final address =
          <String?>[
                place.street,
                place.subLocality,
                place.locality,
                place.administrativeArea,
              ]
              .whereType<String>()
              .map((part) => part.trim())
              .where((part) => part.isNotEmpty)
              .toSet()
              .join(', ');
      if (address.isNotEmpty) setState(() => _address.text = address);
    } on PlatformException {
      // Las coordenadas quedan guardadas; la dirección se puede ingresar a mano.
    } catch (_) {
      // La búsqueda de dirección es opcional y depende del servicio del dispositivo.
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.initialSite == null ? 'Nueva obra' : 'Editar obra',
        style: A2CText.title,
      ),
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
              widget.initialSite == null
                  ? 'Datos de la obra'
                  : 'Actualiza la obra',
              style: A2CText.headline.copyWith(fontSize: 30),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega el nombre, responsable y ubicación para identificarla en el inventario.',
              style: A2CText.body.copyWith(color: A2CColors.inkSecondary),
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nombre de la obra',
                hintText: 'Ej. Obra Juan Ramírez',
              ),
              validator: (value) =>
                  _required(value, 'Ingresa el nombre de la obra'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _owner,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Responsable',
                hintText: 'Nombre y apellido',
              ),
              validator: (value) =>
                  _required(value, 'Ingresa el nombre del responsable'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _address,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Dirección (opcional)',
                hintText: 'Calle, distrito y ciudad',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  onPressed: _pickLocation,
                  icon: const Icon(Icons.pin_drop_outlined, size: 18),
                  label: const Text('Elegir pin en el mapa'),
                  style: TextButton.styleFrom(foregroundColor: A2CColors.ink),
                ),
                TextButton.icon(
                  onPressed: () => openSiteInMaps(
                    address: _address.text,
                    lat: double.tryParse(_lat.text.trim()),
                    lng: double.tryParse(_lng.text.trim()),
                  ),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Abrir Maps'),
                  style: TextButton.styleFrom(foregroundColor: A2CColors.ink),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _coordinate(
                    _lat,
                    _lng,
                    'Latitud (opcional)',
                    '-12.0464',
                    -90,
                    90,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _coordinate(
                    _lng,
                    _lat,
                    'Longitud (opcional)',
                    '-77.0428',
                    -180,
                    180,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Si agregas una coordenada, completa las dos para guardar el punto exacto.',
              style: A2CText.caption.copyWith(color: A2CColors.inkSecondary),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              _FormError(message: _error!.message),
            ],
            const SizedBox(height: 28),
            A2CPrimaryButton(
              label: widget.initialSite == null
                  ? 'Guardar obra'
                  : 'Guardar cambios',
              icon: widget.initialSite == null
                  ? Icons.add_business_outlined
                  : Icons.check_rounded,
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    ),
  );
}

String? _required(String? value, String message) =>
    (value == null || value.trim().length < 3) ? message : null;

Widget _coordinate(
  TextEditingController controller,
  TextEditingController other,
  String label,
  String hint,
  double min,
  double max,
) => TextFormField(
  controller: controller,
  keyboardType: const TextInputType.numberWithOptions(
    decimal: true,
    signed: true,
  ),
  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9.]*'))],
  decoration: InputDecoration(labelText: label, hintText: hint),
  validator: (value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty && other.text.isNotEmpty) {
      return 'Completa las dos';
    }
    final coordinate = double.tryParse(raw);
    if (raw.isNotEmpty && coordinate == null) return 'Número inválido';
    if (coordinate != null && (coordinate < min || coordinate > max)) {
      return 'Fuera de rango';
    }
    return null;
  },
);

class _FormError extends StatelessWidget {
  const _FormError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    label: message,
    child: ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEFEE),
          borderRadius: BorderRadius.circular(A2CRadii.md),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: A2CColors.error),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: A2CText.label)),
          ],
        ),
      ),
    ),
  );
}
