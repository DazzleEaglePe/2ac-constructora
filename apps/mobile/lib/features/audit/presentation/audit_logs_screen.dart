import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/theme/a2c_colors.dart';
import '../../../core/theme/a2c_dimens.dart';
import '../../../core/theme/a2c_typography.dart';
import '../../../shared/widgets/a2c_cards.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../data/audit_repository.dart';
import '../domain/audit_log.dart';

class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  final _actionController = TextEditingController();
  final List<AuditLog> _items = [];
  String? _cursor;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _actionController.dispose();
    super.dispose();
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _cursor = null;
        _items.clear();
      });
    } else {
      setState(() {
        _loadingMore = true;
        _error = null;
      });
    }
    try {
      final page = await ref
          .read(auditRepositoryProvider)
          .list(
            action: _actionController.text.trim(),
            cursor: reset ? null : _cursor,
          );
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _cursor = page.nextCursor;
        _loading = false;
        _loadingMore = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiFailure ? error.message : 'Inténtalo de nuevo.';
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Auditoría', style: A2CText.title),
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: 'Volver',
      ),
    ),
    body: RefreshIndicator(
      color: A2CColors.ink,
      onRefresh: () => _load(reset: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          A2CSpace.screen,
          8,
          A2CSpace.screen,
          32,
        ),
        children: [
          TextField(
            controller: _actionController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _load(reset: true),
            decoration: InputDecoration(
              labelText: 'Filtrar por acción',
              hintText: 'Ej. SITE_CREATED',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                tooltip: 'Aplicar filtro',
                onPressed: () => _load(reset: true),
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: A2CLoadingSkeleton(
                label: 'Cargando los registros de auditoría',
                rows: 3,
              ),
            )
          else if (_error != null && _items.isEmpty)
            EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'No se cargó la auditoría',
              message: _error!,
              actionLabel: 'Reintentar',
              onAction: () => _load(reset: true),
            )
          else if (_items.isEmpty)
            const EmptyState(
              icon: Icons.fact_check_outlined,
              title: 'Sin registros',
              message: 'Las acciones administrativas aparecerán aquí.',
            )
          else ...[
            for (final item in _items) ...[
              _AuditCard(item: item),
              const SizedBox(height: 9),
            ],
            if (_error != null)
              EmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'No se cargaron más registros',
                message: _error!,
                actionLabel: 'Reintentar',
                onAction: () => _load(reset: false),
              )
            else if (_cursor != null)
              OutlinedButton.icon(
                onPressed: _loadingMore ? null : () => _load(reset: false),
                icon: _loadingMore
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          semanticsLabel: 'Cargando más registros de auditoría',
                        ),
                      )
                    : const Icon(Icons.expand_more_rounded),
                label: Text(_loadingMore ? 'Cargando…' : 'Cargar más'),
              ),
          ],
        ],
      ),
    ),
  );
}

class _AuditCard extends StatelessWidget {
  const _AuditCard({required this.item});
  final AuditLog item;

  @override
  Widget build(BuildContext context) => A2CCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.history_rounded,
              size: 19,
              color: A2CColors.inkSecondary,
            ),
            const SizedBox(width: 9),
            Expanded(child: Text(item.action, style: A2CText.bodyStrong)),
            Text(
              DateFormat('dd/MM/yy · HH:mm').format(item.createdAt),
              style: A2CText.caption,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('${item.entityType} · ${item.entityId}', style: A2CText.caption),
        const SizedBox(height: 4),
        Text(
          '${item.userName ?? 'Usuario eliminado'}${item.dni == null ? '' : ' · DNI ${item.dni}'}',
          style: A2CText.caption,
        ),
      ],
    ),
  );
}
