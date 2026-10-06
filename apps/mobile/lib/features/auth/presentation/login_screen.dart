import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/theme/a2c_colors.dart';
import '../../../core/theme/a2c_typography.dart';
import '../../../shared/widgets/a2c_buttons.dart';
import '../application/session_controller.dart';
import '../domain/session_state.dart';
import 'auth_widgets.dart';

/// RF-AUT-01: ingreso con DNI y contraseña (docs/09 §9).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _dni = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  ApiFailure? _error;

  @override
  void dispose() {
    _dni.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(sessionProvider.notifier)
          .login(dni: _dni.text, password: _password.text);
      // El router redirige al panel o al cambio de contraseña.
    } on ApiFailure catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _errorDetail(ApiFailure e) {
    final lockedUntil = e.extra['lockedUntil'];
    if (e.code == 'CUENTA_BLOQUEADA' && lockedUntil is String) {
      final time = DateFormat.Hm('es')
          .format(DateTime.parse(lockedUntil).toLocal());
      return 'Podrás intentarlo de nuevo a las $time.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final reason = session is SessionSignedOut ? session.reason : null;

    return Scaffold(
      backgroundColor: A2CColors.backgroundAlt,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 340,
              child: CustomPaint(painter: LoginHeroPainter()),
            ),
            const Positioned(left: 0, right: 0, top: 0, child: SafetyStripe()),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
                child: Column(
                  children: [
                    const A2CAppIcon(),
                    const SizedBox(height: 14),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'Constructora '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: A2CColors.brandYellow,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'A2C',
                                style: A2CText.headline.copyWith(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      style: A2CText.headline.copyWith(fontSize: 26),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Inventario de herramientas\ny maquinaria en obra',
                      textAlign: TextAlign.center,
                      style: A2CText.label.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 28),
                    _LoginSheet(
                      formKey: _form,
                      dni: _dni,
                      password: _password,
                      obscure: _obscure,
                      loading: _loading,
                      onToggleObscure: () =>
                          setState(() => _obscure = !_obscure),
                      onSubmit: _submit,
                      error: _error,
                      errorDetail: _error == null
                          ? null
                          : _errorDetail(_error!),
                      reason: reason,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginSheet extends StatelessWidget {
  const _LoginSheet({
    required this.formKey,
    required this.dni,
    required this.password,
    required this.obscure,
    required this.loading,
    required this.onToggleObscure,
    required this.onSubmit,
    this.error,
    this.errorDetail,
    this.reason,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController dni;
  final TextEditingController password;
  final bool obscure;
  final bool loading;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final ApiFailure? error;
  final String? errorDetail;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: A2CColors.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: A2CColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 60,
            offset: Offset(0, 30),
          ),
        ],
      ),
      child: AutofillGroup(
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ingresa a tu cuenta',
                style: A2CText.title.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 16),
              if (reason != null && error == null) ...[
                InlineError(message: reason!),
                const SizedBox(height: 14),
              ],
              if (error != null) ...[
                InlineError(message: error!.message, detail: errorDetail),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: dni,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
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
              const SizedBox(height: 14),
              TextFormField(
                controller: password,
                obscureText: obscure,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => onSubmit(),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  hintText: 'Tu contraseña',
                  suffixIcon: IconButton(
                    onPressed: onToggleObscure,
                    tooltip: obscure
                        ? 'Mostrar contraseña'
                        : 'Ocultar contraseña',
                    icon: Icon(
                      obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                  ),
                ),
                validator: (v) =>
                    (v ?? '').isEmpty ? 'Ingresa tu contraseña' : null,
              ),
              const SizedBox(height: 18),
              A2CPrimaryButton(
                label: 'Ingresar',
                onPressed: onSubmit,
                loading: loading,
                loadingLabel: 'Ingresando',
              ),
              const SizedBox(height: 12),
              const Text(
                '¿Olvidaste tu contraseña? Solicítala al administrador.',
                textAlign: TextAlign.center,
                style: A2CText.label,
              ),
              const Divider(height: 32),
              for (final b in const [
                'Inventario por obra en tiempo real',
                'Historial de cada movimiento',
                'Acceso solo para personal autorizado',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 10,
                        backgroundColor: A2CColors.brandYellow,
                        foregroundColor: A2CColors.ink,
                        child: Icon(Icons.check_rounded, size: 14),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          b,
                          style: A2CText.body.copyWith(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
