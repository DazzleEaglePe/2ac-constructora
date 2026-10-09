import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/a2c_colors.dart';
import '../../../core/theme/a2c_typography.dart';
import '../../../shared/widgets/a2c_buttons.dart';
import '../../../shared/widgets/a2c_logo.dart';
import '../application/session_controller.dart';
import '../domain/session_state.dart';
import 'auth_widgets.dart';

/// RF-AUT-01: ingreso con DNI y contraseña. Diseño "Ingreso v2" del canvas:
/// cabecera negra con el título y hoja blanca con el formulario.
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
  bool _remember = true;
  bool _loading = false;
  ApiFailure? _error;

  @override
  void initState() {
    super.initState();
    _restoreRememberedDni();
  }

  Future<void> _restoreRememberedDni() async {
    try {
      final saved = await ref.read(tokenStorageProvider).readRememberedDni();
      // No pisa lo que el usuario ya empezó a escribir.
      if (!mounted || saved == null || _dni.text.isNotEmpty) return;
      if (RegExp(r'^\d{8}$').hasMatch(saved)) _dni.text = saved;
    } catch (_) {
      // Si el almacén seguro no responde, se ingresa el DNI a mano.
    }
  }

  Future<void> _persistRememberedDni(TokenStorage storage, String dni) async {
    try {
      await (_remember
          ? storage.saveRememberedDni(dni)
          : storage.clearRememberedDni());
    } catch (_) {
      // Recordar el DNI es una comodidad: un fallo aquí no invalida el ingreso.
    }
  }

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
    // Se toma antes de ingresar: al cambiar la sesión el router desmonta esta pantalla.
    final storage = ref.read(tokenStorageProvider);
    final dni = _dni.text;
    try {
      await ref
          .read(sessionProvider.notifier)
          .login(dni: dni, password: _password.text);
      await _persistRememberedDni(storage, dni);
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
    final animate = !MediaQuery.of(context).disableAnimations;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: A2CColors.ink,
        body: Stack(
          children: [
            const Positioned(
              right: -130,
              top: 40,
              width: 380,
              height: 285,
              child: CustomPaint(painter: LoginHeaderPainter()),
            ),
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SafetyStripe(height: 6),
            ),
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _Entrance(
                    animate: animate,
                    delay: const Duration(milliseconds: 100),
                    offset: 8,
                    child: const _Header(),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _Entrance(
                    animate: animate,
                    offset: 28,
                    child: _LoginSheet(
                      formKey: _form,
                      dni: _dni,
                      password: _password,
                      obscure: _obscure,
                      remember: _remember,
                      loading: _loading,
                      onToggleObscure: () =>
                          setState(() => _obscure = !_obscure),
                      onToggleRemember: () =>
                          setState(() => _remember = !_remember),
                      onSubmit: _submit,
                      error: _error,
                      errorDetail: _error == null
                          ? null
                          : _errorDetail(_error!),
                      reason: reason,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Cabecera negra: volver al onboarding, logo, título y bajada.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Material(
                  color: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: A2CColors.onInk.withValues(alpha: 0.22),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.go('/onboarding'),
                    child: const SizedBox.square(
                      dimension: 44,
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: A2CColors.onInk,
                        semanticLabel: 'Volver a la introducción',
                      ),
                    ),
                  ),
                ),
                const A2CLogo(height: 32, onDark: true),
              ],
            ),
            const SizedBox(height: 30),
            Semantics(
              header: true,
              child: Text(
                'Ingresa a tu cuenta',
                style: A2CText.display.copyWith(
                  fontSize: 32,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                  color: A2CColors.onInk,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Controla las herramientas y la maquinaria\nde cada obra.',
              style: A2CText.body.copyWith(
                fontSize: 15,
                height: 1.45,
                color: A2CColors.onInk.withValues(alpha: 0.72),
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
    required this.remember,
    required this.loading,
    required this.onToggleObscure,
    required this.onToggleRemember,
    required this.onSubmit,
    this.error,
    this.errorDetail,
    this.reason,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController dni;
  final TextEditingController password;
  final bool obscure;
  final bool remember;
  final bool loading;
  final VoidCallback onToggleObscure;
  final VoidCallback onToggleRemember;
  final VoidCallback onSubmit;
  final ApiFailure? error;
  final String? errorDetail;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: A2CColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 40,
            offset: Offset(0, -12),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: AutofillGroup(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SheetTab(label: 'Ingreso con DNI'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (reason != null && error == null) ...[
                        InlineError(message: reason!),
                        const SizedBox(height: 16),
                      ],
                      if (error != null) ...[
                        InlineError(
                          message: error!.message,
                          detail: errorDetail,
                        ),
                        const SizedBox(height: 16),
                      ],
                      _LabeledField(
                        label: 'DNI',
                        helper: 'Ingrese su nro de documento.',
                        child: TextFormField(
                          controller: dni,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(8),
                          ],
                          style: A2CText.body.copyWith(
                            fontSize: 16,
                            letterSpacing: 1.9,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                          decoration: _fieldDecoration(
                            hint: '00000000',
                            icon: Icons.badge_outlined,
                            suffix: _DniCounter(controller: dni),
                          ),
                          validator: (v) => RegExp(r'^\d{8}$').hasMatch(v ?? '')
                              ? null
                              : 'El DNI tiene 8 dígitos',
                        ),
                      ),
                      const SizedBox(height: 18),
                      _LabeledField(
                        label: 'Contraseña',
                        child: TextFormField(
                          controller: password,
                          obscureText: obscure,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => onSubmit(),
                          style: A2CText.body.copyWith(fontSize: 16),
                          decoration: _fieldDecoration(
                            hint: 'Tu contraseña',
                            icon: Icons.lock_outline_rounded,
                            suffix: Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: IconButton(
                                onPressed: onToggleObscure,
                                tooltip: obscure
                                    ? 'Mostrar contraseña'
                                    : 'Ocultar contraseña',
                                color: A2CColors.inkSecondary,
                                icon: Icon(
                                  obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          validator: (v) => (v ?? '').isEmpty
                              ? 'Ingresa tu contraseña'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _RememberCheck(
                        value: remember,
                        onChanged: onToggleRemember,
                      ),
                      const SizedBox(height: 10),
                      A2CPrimaryButton(
                        label: 'Ingresar',
                        onPressed: onSubmit,
                        loading: loading,
                        loadingLabel: 'Ingresando',
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Row(
                    children: [
                      Expanded(child: Divider()),
                      SizedBox(width: 12),
                      // Una sola línea en teléfonos; en pantallas angostas se parte.
                      Flexible(
                        flex: 12,
                        fit: FlexFit.tight,
                        child: Text(
                          'o solicita tu usuario con tu administrador',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: A2CText.family,
                            fontSize: 13,
                            color: A2CColors.inkTertiary,
                          ),
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(child: Divider()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: A2CColors.borderStrong, width: 1.5),
    );
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: A2CColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIcon: Icon(icon, size: 20, color: A2CColors.inkSecondary),
      suffixIcon: suffix,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: A2CColors.ink, width: 1.5),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: A2CColors.error, width: 1.5),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: A2CColors.error, width: 1.5),
      ),
    );
  }
}

/// Pestaña única centrada con subrayado negro (eco de la referencia).
class _SheetTab extends StatelessWidget {
  const _SheetTab({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: A2CColors.border)),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.fromLTRB(2, 20, 2, 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: A2CColors.ink, width: 3)),
          ),
          child: Text(
            label,
            style: A2CText.bodyStrong.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Etiqueta arriba del campo y halo amarillo al enfocarlo.
class _LabeledField extends StatefulWidget {
  const _LabeledField({required this.label, required this.child, this.helper});

  final String label;
  final String? helper;
  final Widget child;

  @override
  State<_LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<_LabeledField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.label, style: A2CText.bodyStrong.copyWith(fontSize: 14)),
        const SizedBox(height: 8),
        Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onFocusChange: (f) => setState(() => _focused = f),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // El halo cubre solo la caja del campo, no el texto de ayuda.
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 54,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      if (_focused)
                        BoxShadow(
                          color: A2CColors.brandYellow.withValues(alpha: 0.45),
                          spreadRadius: 4,
                        ),
                    ],
                  ),
                ),
              ),
              widget.child,
            ],
          ),
        ),
        if (widget.helper != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.helper!,
            style: A2CText.caption.copyWith(color: A2CColors.inkSecondary),
          ),
        ],
      ],
    );
  }
}

class _DniCounter extends StatelessWidget {
  const _DniCounter({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (_, value, _) {
        final n = value.text.length;
        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            widthFactor: 1,
            child: Text(
              '$n/8',
              semanticsLabel: '$n de 8 dígitos',
              style: A2CText.label.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: n == 8 ? A2CColors.ink : A2CColors.inkTertiary,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RememberCheck extends StatelessWidget {
  const _RememberCheck({required this.value, required this.onChanged});

  final bool value;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      label: 'Recordar mi DNI en este equipo',
      excludeSemantics: true,
      child: InkWell(
        onTap: onChanged,
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: value ? A2CColors.brandYellow : A2CColors.background,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    width: 1.5,
                    color: value ? A2CColors.ink : const Color(0x4D000000),
                  ),
                ),
                child: value
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: A2CColors.ink,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Recordar mi DNI en este equipo',
                  style: A2CText.body.copyWith(
                    fontSize: 14,
                    color: const Color(0xFF262626),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Entrada suave (fundido + subida) al abrir la pantalla.
class _Entrance extends StatelessWidget {
  const _Entrance({
    required this.animate,
    required this.offset,
    required this.child,
    this.delay = Duration.zero,
  });

  final bool animate;
  final double offset;
  final Duration delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!animate) return child;
    const curve = Cubic(0.2, 0.8, 0.2, 1);
    final total = delay + const Duration(milliseconds: 550);
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: curve),
      child: child,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * offset),
          child: child,
        ),
      ),
    );
  }
}
