import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/theme/a2c_colors.dart';
import '../../../core/theme/a2c_dimens.dart';
import '../../../core/theme/a2c_typography.dart';
import '../../../shared/widgets/a2c_buttons.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/app_user.dart';
import '../data/users_repository.dart';

/// RF-USR-01…05: gestión de usuarios (solo administradores).
class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersListProvider);
    final me = ref.watch(currentUserProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: A2CColors.ink,
          onRefresh: () => ref.refresh(usersListProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              A2CSpace.screen,
              28,
              A2CSpace.screen,
              120,
            ),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Usuarios',
                          style: A2CText.headline.copyWith(fontSize: 36),
                        ),
                        Text(
                          users.whenOrNull(
                                data: (l) => _peopleLabel(
                                  l.where((u) => u.active).length,
                                ),
                              ) ??
                              ' ',
                          style: A2CText.label.copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  A2CPrimaryButton(
                    label: 'Nuevo',
                    icon: Icons.add_rounded,
                    expand: false,
                    onPressed: () => _openCreate(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...users.when(
                loading: () => [
                  const A2CLoadingRows(label: 'Cargando usuarios'),
                ],
                error: (e, _) => [
                  EmptyState(
                    icon: Icons.cloud_off_rounded,
                    title: 'No se pudo cargar',
                    message: e is ApiFailure
                        ? e.message
                        : 'Inténtalo de nuevo.',
                    actionLabel: 'Reintentar',
                    onAction: () => ref.invalidate(usersListProvider),
                  ),
                ],
                data: (list) => list.isEmpty
                    ? [
                        const EmptyState(
                          icon: Icons.group_outlined,
                          title: 'Aún no hay usuarios',
                          message: 'Crea el primero con "Nuevo".',
                        ),
                      ]
                    : [
                        for (final u in list)
                          _UserRow(
                            user: u,
                            isMe: u.id == me?.id,
                            onTap: () => _openActions(
                              context,
                              ref,
                              u,
                              isMe: u.id == me?.id,
                            ),
                          ),
                      ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCreate(BuildContext context, WidgetRef ref) async {
    final created = await showModalBottomSheet<AppUser>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true, // por encima de la barra flotante
      showDragHandle: true,
      backgroundColor: A2CColors.background,
      builder: (_) => const _CreateUserSheet(),
    );
    if (created != null && context.mounted) {
      ref.invalidate(usersListProvider);
      _toast(
        context,
        'Usuario creado. Deberá cambiar su contraseña al ingresar.',
      );
    }
  }

  Future<void> _openActions(
    BuildContext context,
    WidgetRef ref,
    AppUser user, {
    required bool isMe,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      backgroundColor: A2CColors.background,
      builder: (sheetContext) => _UserActionsSheet(user: user, isMe: isMe),
    );
    ref.invalidate(usersListProvider);
  }
}

String _peopleLabel(int n) =>
    n == 1 ? '1 persona con acceso' : '$n personas con acceso';

void _toast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user, required this.isMe, required this.onTap});

  final AppUser user;
  final bool isMe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = user.isAdmin
        ? (A2CColors.ink, A2CColors.onInk)
        : (A2CColors.brandYellow, A2CColors.ink);
    final last = user.lastMovementAt;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: A2CColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(A2CRadii.md),
          side: const BorderSide(color: A2CColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Opacity(
            opacity: user.active ? 1 : 0.55,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 23,
                    backgroundColor: bg,
                    foregroundColor: fg,
                    child: Text(
                      user.initials,
                      style: A2CText.bodyStrong.copyWith(color: fg),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.fullName,
                                style: A2CText.bodyStrong.copyWith(
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isMe) const _Tag('Tú'),
                            if (!user.active) const _Tag('Desactivado'),
                          ],
                        ),
                        Text(
                          'DNI ${user.dni} · ${user.role.label}',
                          style: A2CText.code,
                        ),
                        Text(
                          last == null
                              ? 'Sin movimientos todavía'
                              : 'Último movimiento: ${DateFormat('d MMM, HH:mm', 'es').format(last.toLocal())}',
                          style: A2CText.caption,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.more_vert_rounded,
                    color: A2CColors.inkSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(left: 6),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: const ShapeDecoration(
      color: A2CColors.brandYellowSoft,
      shape: StadiumBorder(),
    ),
    child: Text(
      label,
      style: A2CText.caption.copyWith(
        color: A2CColors.ink,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _RolePicker extends StatelessWidget {
  const _RolePicker({required this.value, required this.onChanged});

  final Role value;
  final ValueChanged<Role> onChanged;

  @override
  Widget build(BuildContext context) => SegmentedButton<Role>(
    showSelectedIcon: false,
    segments: [
      for (final r in Role.values)
        ButtonSegment(value: r, label: Text(r.label)),
    ],
    selected: {value},
    onSelectionChanged: (s) => onChanged(s.first),
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? A2CColors.ink
            : A2CColors.surface,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (s) =>
            s.contains(WidgetState.selected) ? A2CColors.onInk : A2CColors.ink,
      ),
      textStyle: const WidgetStatePropertyAll(A2CText.bodyStrong),
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
    ),
  );
}

class _CreateUserSheet extends ConsumerStatefulWidget {
  const _CreateUserSheet();

  @override
  ConsumerState<_CreateUserSheet> createState() => _CreateUserSheetState();
}

class _CreateUserSheetState extends ConsumerState<_CreateUserSheet> {
  final _form = GlobalKey<FormState>();
  final _dni = TextEditingController();
  final _name = TextEditingController();
  final _password = TextEditingController();
  Role _role = Role.operador;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _dni.dispose();
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await ref
          .read(usersRepositoryProvider)
          .create(
            dni: _dni.text,
            fullName: _name.text.trim(),
            role: _role,
            temporaryPassword: _password.text,
          );
      if (mounted) Navigator.of(context).pop(user);
    } on ApiFailure catch (e) {
      setState(() => _error = e.detail ?? e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nuevo usuario', style: A2CText.title.copyWith(fontSize: 20)),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Semantics(
                container: true,
                liveRegion: true,
                label: _error!,
                child: ExcludeSemantics(
                  child: Text(
                    _error!,
                    style: A2CText.bodyStrong.copyWith(color: A2CColors.error),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _dni,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              decoration: const InputDecoration(
                labelText: 'DNI',
                hintText: 'Número de documento',
              ),
              validator: (v) => RegExp(r'^\d{8}$').hasMatch(v ?? '')
                  ? null
                  : 'El DNI tiene 8 dígitos',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                hintText: 'Nombre y apellido',
              ),
              validator: (v) => (v ?? '').trim().length >= 3
                  ? null
                  : 'Ingresa el nombre completo',
            ),
            const SizedBox(height: 12),
            const Text('Rol', style: A2CText.label),
            const SizedBox(height: 8),
            _RolePicker(
              value: _role,
              onChanged: (r) => setState(() => _role = r),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              decoration: InputDecoration(
                labelText: 'Contraseña temporal',
                hintText: 'Mínimo 8, con letras y números',
                suffixIcon: TextButton(
                  onPressed: () =>
                      setState(() => _password.text = _suggestPassword()),
                  child: const Text('Generar'),
                ),
              ),
              validator: (v) {
                final s = v ?? '';
                if (s.length < 8 ||
                    !RegExp(r'[A-Za-z]').hasMatch(s) ||
                    !RegExp(r'\d').hasMatch(s)) {
                  return 'Mínimo 8 caracteres, con letras y números';
                }
                return null;
              },
            ),
            const SizedBox(height: 6),
            const Text(
              'El usuario la cambiará en su primer ingreso (vence en 72 h).',
              style: A2CText.caption,
            ),
            const SizedBox(height: 18),
            A2CPrimaryButton(
              label: 'Guardar',
              onPressed: _save,
              loading: _loading,
              loadingLabel: 'Guardando usuario',
            ),
          ],
        ),
      ),
    );
  }

  /// Sugerencia aleatoria (generador criptográfico) con letras y números.
  String _suggestPassword() {
    const letters = 'ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz';
    const digits = '23456789';
    final rnd = Random.secure();
    final chars = [
      for (var i = 0; i < 8; i++) letters[rnd.nextInt(letters.length)],
      for (var i = 0; i < 2; i++) digits[rnd.nextInt(digits.length)],
    ]..shuffle(rnd);
    return chars.join();
  }
}

class _UserActionsSheet extends ConsumerStatefulWidget {
  const _UserActionsSheet({required this.user, required this.isMe});

  final AppUser user;
  final bool isMe;

  @override
  ConsumerState<_UserActionsSheet> createState() => _UserActionsSheetState();
}

class _UserActionsSheetState extends ConsumerState<_UserActionsSheet> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on ApiFailure catch (e) {
      if (mounted) _toast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final repo = ref.read(usersRepositoryProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(u.fullName, style: A2CText.title.copyWith(fontSize: 20)),
            Text('DNI ${u.dni} · ${u.role.label}', style: A2CText.code),
            const SizedBox(height: 16),
            if (_busy) const LinearProgressIndicator(),
            _ActionTile(
              icon: Icons.badge_outlined,
              label: u.isAdmin
                  ? 'Cambiar a Operador'
                  : 'Cambiar a Administrador',
              onTap: _busy
                  ? null
                  : () => _run(() async {
                      await repo.update(
                        u.id,
                        role: u.isAdmin ? Role.operador : Role.admin,
                      );
                      if (context.mounted) Navigator.pop(context);
                    }),
            ),
            _ActionTile(
              icon: Icons.key_rounded,
              label: 'Restablecer contraseña',
              onTap: _busy
                  ? null
                  : () => _run(() async {
                      final temp = await repo.resetPassword(u.id);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      await showDialog<void>(
                        context: context,
                        builder: (_) => _TempPasswordDialog(
                          name: u.fullName,
                          password: temp,
                        ),
                      );
                    }),
            ),
            if (!widget.isMe)
              _ActionTile(
                icon: u.active
                    ? Icons.block_rounded
                    : Icons.check_circle_outline_rounded,
                label: u.active ? 'Desactivar usuario' : 'Reactivar usuario',
                danger: u.active,
                onTap: _busy
                    ? null
                    : () => _run(() async {
                        if (u.active) {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('¿Desactivar usuario?'),
                              content: Text(
                                '${u.fullName} no podrá ingresar. Su historial se conserva.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(c, false),
                                  child: const Text('Cancelar'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  child: const Text('Desactivar'),
                                ),
                              ],
                            ),
                          );
                          if (ok != true) return;
                        }
                        await repo.setActive(u.id, !u.active);
                        if (context.mounted) Navigator.pop(context);
                      }),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? A2CColors.error : A2CColors.ink;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: 52,
      leading: Icon(icon, color: color),
      title: Text(label, style: A2CText.bodyStrong.copyWith(color: color)),
      onTap: onTap,
    );
  }
}

class _TempPasswordDialog extends StatelessWidget {
  const _TempPasswordDialog({required this.name, required this.password});

  final String name;
  final String password;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Contraseña temporal'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Entrégala a $name. Solo se muestra esta vez y vence en 72 h.'),
        const SizedBox(height: 16),
        SelectableText(
          password,
          style: A2CText.code.copyWith(
            fontSize: 24,
            color: A2CColors.ink,
            letterSpacing: 2,
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Clipboard.setData(ClipboardData(text: password)),
        child: const Text('Copiar'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Listo'),
      ),
    ],
  );
}
