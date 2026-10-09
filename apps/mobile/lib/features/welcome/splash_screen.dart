import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/redirect.dart';
import '../../core/storage/preferences.dart';
import '../../core/theme/a2c_colors.dart';
import '../../core/theme/a2c_typography.dart';
import '../auth/application/session_controller.dart';
import '../auth/domain/session_state.dart';
import '../auth/presentation/auth_widgets.dart';
import 'a2c_splash_animation.dart';

/// RF-BIE-01/02: entrada animada del logo mientras se verifica la sesión.
/// Sale cuando la animación terminó (≈2,7 s) y la sesión está verificada; un
/// toque la salta. En el primer uso se muestra "Toca para continuar".
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _animationDone = false;
  bool _left = false;
  late final bool _firstUse = !ref.read(onboardingSeenProvider);

  @override
  void initState() {
    super.initState();
    // La verificación de sesión corre en paralelo a la animación.
    Future.microtask(() async {
      await ref.read(sessionProvider.notifier).restore();
      _maybeLeave();
    });
  }

  void _maybeLeave({bool skip = false}) {
    if (!mounted || _left) return;
    final session = ref.read(sessionProvider);
    if (session is SessionUnknown) return;
    if (!skip && !_animationDone) return;
    _left = true;
    context.go(routeAfterSplash(session: session, onboardingSeen: !_firstUse));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: A2CColors.background,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _maybeLeave(skip: true),
          child: Stack(
            children: [
              const Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: SafetyStripe(height: 6),
              ),
              Align(
                alignment: const Alignment(0, -0.12),
                child: A2CSplashAnimation(
                  onComplete: () {
                    _animationDone = true;
                    _maybeLeave();
                  },
                ),
              ),
              if (_firstUse)
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 56,
                  child: SafeArea(child: Center(child: _TapHint())),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TapHint extends StatelessWidget {
  const _TapHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: const ShapeDecoration(
        color: A2CColors.background,
        shape: StadiumBorder(side: BorderSide(color: A2CColors.border)),
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
    );
  }
}
