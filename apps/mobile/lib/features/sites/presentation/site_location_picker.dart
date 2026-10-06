import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/a2c_colors.dart';
import '../../../core/theme/a2c_typography.dart';

class SiteLocationPicker extends StatefulWidget {
  const SiteLocationPicker({super.key, this.initialPosition});

  final LatLng? initialPosition;

  @override
  State<SiteLocationPicker> createState() => _SiteLocationPickerState();
}

class _SiteLocationPickerState extends State<SiteLocationPicker> {
  static const _lima = LatLng(-12.0464, -77.0428);
  late LatLng _selected = widget.initialPosition ?? _lima;
  bool _tileLoadFailed = false;
  int _tileLayerRevision = 0;

  void _onTileError(TileImage tile, Object error, StackTrace? stackTrace) {
    if (!mounted || _tileLoadFailed) return;
    setState(() => _tileLoadFailed = true);
  }

  void _retryTiles() => setState(() {
    _tileLoadFailed = false;
    _tileLayerRevision++;
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ubicación de la obra', style: A2CText.title),
          const SizedBox(height: 5),
          Text(
            'Toca el mapa para colocar el pin y vuelve a tocar para ajustar el punto.',
            style: A2CText.caption.copyWith(color: A2CColors.inkSecondary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 380,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: _selected,
                      initialZoom: widget.initialPosition == null ? 12 : 15,
                      onTap: (_, point) => setState(() => _selected = point),
                    ),
                    children: [
                      TileLayer(
                        key: ValueKey(_tileLayerRevision),
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'pe.a2c.a2c_inventario',
                        errorTileCallback: _onTileError,
                        evictErrorTileStrategy: EvictErrorTileStrategy.dispose,
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selected,
                            width: 48,
                            height: 56,
                            child: const Icon(
                              Icons.location_pin,
                              color: A2CColors.brandYellow,
                              size: 48,
                              shadows: [
                                Shadow(blurRadius: 3, color: Colors.black54),
                              ],
                            ),
                          ),
                        ],
                      ),
                      RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution(
                            '© OpenStreetMap contributors',
                            onTap: () => launchUrl(
                              Uri.parse(
                                'https://www.openstreetmap.org/copyright',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_tileLoadFailed)
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).colorScheme.surface,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Semantics(
                                  container: true,
                                  liveRegion: true,
                                  label:
                                      'No se pudo cargar el mapa. Puedes '
                                      'reintentar o ingresar las coordenadas '
                                      'manualmente.',
                                  child: const ExcludeSemantics(
                                    child: Text(
                                      'No se pudo cargar el mapa. Puedes '
                                      'ingresar las coordenadas manualmente.',
                                    ),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _retryTiles,
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            container: true,
            liveRegion: true,
            label:
                'Coordenadas seleccionadas: latitud ${_selected.latitude.toStringAsFixed(6)}, longitud ${_selected.longitude.toStringAsFixed(6)}',
            child: ExcludeSemantics(
              child: Text(
                '${_selected.latitude.toStringAsFixed(6)}, ${_selected.longitude.toStringAsFixed(6)}',
                style: A2CText.code,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(_selected),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Usar esta ubicación'),
            ),
          ),
        ],
      ),
    ),
  );
}
