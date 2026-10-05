import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/redirect.dart';
import '../../core/storage/preferences.dart';
import '../../core/theme/a2c_colors.dart';
import '../../core/theme/a2c_typography.dart';
import '../auth/application/session_controller.dart';
import '../auth/domain/session_state.dart';
import 'a2c_splash_animation.dart';

/// RF-BIE-01/02: splash con la animación del logo mientras se verifica la sesión.
/// - Primer uso: se ve el ciclo completo (o se toca para continuar).
/// - Usos siguientes: mínimo 1,5 s y en cuanto la sesión esté verificada.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const minimumDuration = Duration(milliseconds: 1500);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _minimumElapsed = false;
  bool _cycleDone = false;
  bool _left = false;
  Timer? _timer;

  bool get _firstUse => !ref.read(onboardingSeenProvider);

  @override
  void initState() {
    super.initState();
    _timer = Timer(SplashScreen.minimumDuration, () {
      _minimumElapsed = true;
      _maybeLeave();
    });
    // La verificación de sesión corre en paralelo a la animación.
    Future.microtask(() async {
      await ref.read(sessionProvider.notifier).restore();
      _maybeLeave();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _maybeLeave({bool skip = false}) {
    if (!mounted || _left) return;
    final session = ref.read(sessionProvider);
    if (session is SessionUnknown) return;
    final ready = skip || (_firstUse ? _cycleDone : _minimumElapsed);
    if (!ready) return;
    _left = true;
    context.go(routeAfterSplash(session: session, onboardingSeen: !_firstUse));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _maybeLeave(skip: true),
        child: Stack(
          children: [
            Positioned.fill(
              child: A2CSplashAnimation(
                onCycleComplete: () {
                  _cycleDone = true;
                  _maybeLeave();
                },
              ),
            ),
            if (_firstUse)
              Positioned(
                left: 0,
                right: 0,
                bottom: 56,
                child: SafeArea(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: const ShapeDecoration(
                        color: A2CColors.background,
                        shape: StadiumBorder(),
                        shadows: [
                          BoxShadow(
                            color: Color(0x1F000000),
                            blurRadius: 24,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Toca para continuar',
                            style: A2CText.label.copyWith(
                              color: A2CColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: A2CColors.ink,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
