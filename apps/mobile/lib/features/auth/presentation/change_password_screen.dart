import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/theme/a2c_colors.dart';
import '../../../core/theme/a2c_dimens.dart';
import '../../../core/theme/a2c_typography.dart';
import '../../../shared/widgets/a2c_buttons.dart';
import '../application/session_controller.dart';
import 'auth_widgets.dart';

/// Requisitos de la contraseña (docs/07 §2), evaluados en vivo.
List<(String, bool)> passwordChecks(String value, String dni) => [
  ('Al menos 8 caracteres', value.length >= 8),
  ('Al menos una letra', RegExp(r'[A-Za-zÁÉÍÓÚáéíóúÑñ]').hasMatch(value)),
  ('Al menos un número', RegExp(r'\d').hasMatch(value)),
  ('Sin tu DNI', value.isNotEmpty && !value.contains(dni)),
];

/// RF-AUT-05: cambio obligatorio de la contraseña temporal.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  ApiFailure? _error;

  @override
  void initState() {
    super.initState();
    _next.addListener(() => setState(() {}));
    _confirm.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit(bool valid) async {
    if (!valid) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(sessionProvider.notifier)
          .changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );
    } on ApiFailure catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final checks = passwordChecks(_next.text, user?.dni ?? '');
    final matches = _next.text.isNotEmpty && _next.text == _confirm.text;
    final valid =
        _current.text.isNotEmpty && checks.every((c) => c.$2) && matches;

    return Scaffold(
      backgroundColor: A2CColors.backgroundAlt,
      appBar: AppBar(
        backgroundColor: A2CColors.backgroundAlt,
        actions: [
          TextButton(
            onPressed: () => ref.read(sessionProvider.notifier).logout(),
            child: const Text('Salir'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            A2CSpace.screen,
            0,
            A2CSpace.screen,
            24,
          ),
          children: [
            const Text('Crea tu\ncontraseña', style: A2CText.headline),
            const SizedBox(height: 8),
            Text(
              'Hola${user == null ? '' : ', ${user.fullName.split(' ').first}'}. Tu contraseña actual es temporal; cámbiala para continuar.',
              style: A2CText.body.copyWith(color: A2CColors.inkSecondary),
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              InlineError(message: _error!.message, detail: _error!.detail),
              const SizedBox(height: 14),
            ],
            _PasswordField(
              label: 'Contraseña temporal',
              controller: _current,
              autofill: AutofillHints.password,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 14),
            _PasswordField(
              label: 'Nueva contraseña',
              controller: _next,
              autofill: AutofillHints.newPassword,
            ),
            const SizedBox(height: 10),
            for (final (label, ok) in checks)
              Semantics(
                container: true,
                label: '$label. ${ok ? 'Cumplido' : 'Pendiente'}',
                child: ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          ok
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked,
                          size: 18,
                          color: ok ? A2CColors.ink : A2CColors.inkTertiary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: A2CText.label.copyWith(
                            color: ok ? A2CColors.ink : A2CColors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            _PasswordField(
              label: 'Repite la nueva contraseña',
              controller: _confirm,
              autofill: AutofillHints.newPassword,
            ),
            if (_confirm.text.isNotEmpty && !matches)
              Semantics(
                container: true,
                liveRegion: true,
                label: 'Las contraseñas no coinciden',
                child: ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Las contraseñas no coinciden',
                      style: A2CText.label.copyWith(color: A2CColors.error),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            A2CPrimaryButton(
              label: 'Guardar y continuar',
              onPressed: valid ? () => _submit(valid) : null,
              loading: _loading,
              loadingLabel: 'Actualizando contraseña',
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.autofill,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String autofill;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    obscureText: true,
    autofillHints: [autofill],
    onChanged: (_) => onChanged?.call(),
    decoration: InputDecoration(labelText: label),
  );
}
