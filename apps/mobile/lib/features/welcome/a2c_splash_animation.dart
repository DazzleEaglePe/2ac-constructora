import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/a2c_colors.dart';
import '../../core/theme/a2c_typography.dart';
import '../../shared/widgets/a2c_logo.dart';
import 'keyframes.dart';

/// Animación del logo A2C para el splash: bucle de 6,5 s en un escenario de
/// 720×720 escalado al ancho disponible (docs/09 §8, ADR-08).
class A2CSplashAnimation extends StatefulWidget {
  const A2CSplashAnimation({super.key, this.onCycleComplete});

  /// Se llama al terminar el primer ciclo completo.
  final VoidCallback? onCycleComplete;

  static const cycle = Duration(milliseconds: 6500);

  @override
  State<A2CSplashAnimation> createState() => _A2CSplashAnimationState();
}

class _A2CSplashAnimationState extends State<A2CSplashAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: A2CSplashAnimation.cycle)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            widget.onCycleComplete?.call();
            _controller.repeat();
          }
        });

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
    if (_reduceMotion) {
      _controller.value =
          0.75; // estado final estático: monograma + CONSTRUCTORA
    } else if (!_controller.isAnimating) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Constructora A2C, cargando',
      image: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: SplashPainter(_reduceMotion ? 0.75 : _controller.value),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Dibuja un fotograma de la animación para un progreso `t` (0–1).
class SplashPainter extends CustomPainter {
  SplashPainter(this.t);

  final double t;

  static Color backgroundAt(double t) => step(t, const [
    (0.0, Color(0xFFE6E6E3)),
    (0.08, A2CColors.brandYellow),
    (0.22, A2CColors.ink),
    (0.40, Color(0xFFFFFFFF)),
    (0.54, Color(0xFFF3F0E8)),
    (0.88, Color(0xFFE6E6E3)),
  ]);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = backgroundAt(t));

    // Escenario cuadrado de 720×720 centrado y escalado al ancho.
    final scale = math.min(size.width, size.height) / 720;
    canvas.save();
    canvas.translate(
      (size.width - 720 * scale) / 2,
      (size.height - 720 * scale) / 2,
    );
    canvas.scale(scale);
    canvas.clipRect(const Rect.fromLTWH(-2000, -2000, 4720, 4720));

    _paintBeam(canvas);
    _paintMonogram(canvas);
    _paintWordmark(canvas);
    _paintWipe(canvas, size, scale);
    canvas.restore();
  }

  void _paintBeam(Canvas canvas) {
    final dx = keyframe(t, const [
      (0.23, -700),
      (0.30, -80),
      (0.34, -40),
      (0.39, 800),
    ], curve: const Cubic(0.6, 0, 0.3, 1));
    if (dx <= -700 || dx >= 800) return;
    canvas.save();
    canvas.translate(260 + 75 + dx, -240 + 600);
    canvas.rotate(20 * math.pi / 180);
    canvas.drawRect(
      const Rect.fromLTWH(-75, -600, 150, 1200),
      Paint()..color = A2CColors.brandYellow,
    );
    canvas.restore();
  }

  void _paintMonogram(Canvas canvas) {
    final ink = step(t, const [
      (0.0, A2CColors.ink),
      (0.22, Color(0xFFFFFFFF)),
      (0.40, A2CColors.ink),
    ]);
    final two = step(t, const [
      (0.0, A2CColors.brandYellow),
      (0.08, A2CColors.ink),
      (0.22, A2CColors.brandYellow),
    ]);

    final s = keyframe(t, const [
      (0, 1),
      (0.02, 0.9),
      (0.05, 1.05),
      (0.08, 1),
      (0.54, 1),
      (0.60, 0.7),
      (0.86, 0.7),
      (0.92, 1),
    ]);
    final ty = keyframe(t, const [
      (0.54, 0),
      (0.60, -40),
      (0.86, -40),
      (0.92, 0),
    ]);
    final aScale = keyframe(t, const [
      (0.09, 1),
      (0.13, 7),
      (0.16, 5.5),
      (0.18, 5.5),
      (0.21, 1),
    ]);
    final cScale = keyframe(t, const [
      (0.11, 1),
      (0.15, 4),
      (0.18, 4),
      (0.21, 1),
    ]);
    final twoScale = keyframe(t, const [
      (0.41, 1),
      (0.46, 5),
      (0.50, 5),
      (0.53, 1),
    ]);

    canvas.save();
    // Bloque del monograma: 320×120 en (200, 300), escalado desde su centro.
    canvas.translate(360, 360 + ty);
    canvas.scale(s);
    canvas.translate(-160, -60);

    _drawScaledX(canvas, A2CLogoPainter.letterA(), ink, aScale, pivotX: 128);
    canvas.save();
    canvas.translate(180, 60);
    canvas.scale(twoScale);
    canvas.translate(-180, -60);
    canvas.drawPath(A2CLogoPainter.digitTwo(), Paint()..color = two);
    canvas.restore();
    _drawScaledX(canvas, A2CLogoPainter.letterC(), ink, cScale, pivotX: 232);
    canvas.restore();
  }

  void _drawScaledX(
    Canvas canvas,
    Path path,
    Color color,
    double sx, {
    required double pivotX,
  }) {
    canvas.save();
    canvas.translate(pivotX, 0);
    canvas.scale(sx, 1);
    canvas.translate(-pivotX, 0);
    canvas.drawPath(path, Paint()..color = color);
    canvas.restore();
  }

  void _paintWordmark(Canvas canvas) {
    // CONSTRUCTORA: se revela de izquierda a derecha y sale por la izquierda.
    final revealEnd = keyframe(t, const [(0.56, 0), (0.64, 1)]);
    final hideStart = keyframe(t, const [(0.86, 0), (0.91, 1)]);
    if (revealEnd > 0 && hideStart < 1) {
      final painter = TextPainter(
        text: TextSpan(
          text: 'CONSTRUCTORA',
          style: A2CText.display.copyWith(
            fontSize: 46,
            fontWeight: FontWeight.w800,
            letterSpacing: 46 * 0.14,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = (720 - painter.width) / 2;
      canvas.save();
      canvas.clipRect(
        Rect.fromLTRB(
          x + painter.width * hideStart,
          380,
          x + painter.width * revealEnd,
          460,
        ),
      );
      painter.paint(canvas, Offset(x, 398));
      canvas.restore();
    }

    final bar = keyframe(t, const [(0.62, 0), (0.68, 1), (0.86, 1), (0.90, 0)]);
    if (bar > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: const Offset(360, 466),
            width: 120 * bar,
            height: 8,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = A2CColors.brandYellow,
      );
    }

    final tag = keyframe(t, const [
      (0.66, 0),
      (0.72, 1),
      (0.86, 1),
      (0.90, 0),
    ], curve: Curves.ease);
    if (tag > 0) {
      final painter = TextPainter(
        text: TextSpan(
          text: 'TU VISIÓN — NUESTRA EJECUCIÓN',
          style: A2CText.label.copyWith(
            fontSize: 17,
            letterSpacing: 17 * 0.2,
            color: A2CColors.inkSecondary.withValues(alpha: tag),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset((720 - painter.width) / 2, 490 + 10 * (1 - tag)),
      );
    }
  }

  void _paintWipe(Canvas canvas, Size size, double scale) {
    // Barrido de la franja de seguridad que tapa el corte negro → blanco.
    final dx = keyframe(t, const [
      (0.37, -1500),
      (0.42, 800),
    ], curve: const Cubic(0.7, 0, 0.3, 1));
    if (dx <= -1500 || dx >= 800) return;
    final band = Rect.fromLTWH(dx, -400, 1400, 1520);
    canvas.save();
    canvas.clipRect(band);
    canvas.drawRect(band, Paint()..color = A2CColors.ink);
    // Franjas a -45° de 48 px separadas 96 px (medido en perpendicular).
    final yellow = Paint()
      ..color = A2CColors.brandYellow
      ..strokeWidth = 48;
    for (
      var x = band.left - band.height;
      x < band.right + band.height;
      x += 96 * math.sqrt2
    ) {
      canvas.drawLine(
        Offset(x, band.bottom),
        Offset(x + band.height, band.top),
        yellow,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(SplashPainter old) => old.t != t;
}
