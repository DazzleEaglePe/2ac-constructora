import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../core/theme/a2c_colors.dart';
import '../../core/theme/a2c_typography.dart';
import '../../shared/widgets/a2c_logo.dart';

/// Línea de tiempo de la entrada "Trazado" (opción A del canvas, docs/09 §8),
/// en segundos de diseño. Cada tramo devuelve su progreso 0–1 ya con su curva.
abstract final class SplashTimeline {
  /// Duración de diseño; la app la reproduce a [A2CSplashAnimation.speed].
  static const total = 3.224;

  static const _draw = Cubic(0.6, 0, 0.2, 1);
  static const _rise = Cubic(0.2, 0.8, 0.2, 1);
  static const _fill = Cubic(0.7, 0, 0.2, 1);

  static double _segment(double t, double start, double end, Curve curve) {
    final local = ((t * total - start) / (end - start)).clamp(0.0, 1.0);
    return curve.transform(local);
  }

  /// 1. Marco y marcas finas, una tras otra.
  static double thinLine(double t, int i) =>
      _segment(t, i * 0.03, 0.624 + i * 0.03, _draw);

  /// 2. Líneas de cota.
  static double dimLine(double t, int i) =>
      _segment(t, 0.416 + i * 0.05, 1.144 + i * 0.05, _draw);

  /// 3. Flechas.
  static double arrows(double t) => _segment(t, 0.988, 1.3, Curves.ease);

  /// 4. Las hojas de la A suben desde la línea base.
  static double bladeLeft(double t) => _segment(t, 1.144, 1.768, _rise);
  static double bladeRight(double t) => _segment(t, 1.404, 2.028, _rise);

  /// 5. El 2 se llena de izquierda a derecha.
  static double two(double t) => _segment(t, 1.716, 2.444, _fill);

  /// 6. Nombre y lema.
  static double wordmark(double t) => _segment(t, 2.392, 2.912, _rise);
  static double tagline(double t) => _segment(t, 2.704, 3.224, Curves.ease);
}

/// Entrada animada del logo "Cota": las cotas se trazan y el monograma se
/// construye. Se reproduce una vez; con "reducir movimiento" muestra el final.
class A2CSplashAnimation extends StatefulWidget {
  const A2CSplashAnimation({super.key, this.onComplete});

  /// Se llama cuando termina la animación (o de inmediato sin movimiento).
  final VoidCallback? onComplete;

  /// La app la reproduce un poco más rápida que el canvas (≈2,7 s).
  static const speed = 1.2;
  static final duration = Duration(
    milliseconds: (SplashTimeline.total / speed * 1000).round(),
  );

  @override
  State<A2CSplashAnimation> createState() => _A2CSplashAnimationState();
}

class _A2CSplashAnimationState extends State<A2CSplashAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: A2CSplashAnimation.duration)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) widget.onComplete?.call();
        });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.onComplete?.call(),
      );
    } else {
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
      label: 'A2 Constructora. Tu visión, nuestra ejecución. Cargando',
      image: true,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 280,
                  height: 210,
                  child: CustomPaint(painter: SplashPainter(t)),
                ),
                const SizedBox(height: 30),
                _Reveal(
                  progress: SplashTimeline.wordmark(t),
                  offset: 12,
                  child: SizedBox(
                    width: 316,
                    child: FittedBox(
                      child: Text(
                        'A2 CONSTRUCTORA',
                        style: A2CText.wordmark.copyWith(fontSize: 40),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                _Reveal(
                  progress: SplashTimeline.tagline(t),
                  offset: 8,
                  child: SizedBox(
                    width: 283,
                    child: FittedBox(
                      child: Text(
                        'TU VISIÓN · NUESTRA EJECUCIÓN',
                        style: A2CText.tagline.copyWith(fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.progress,
    required this.offset,
    required this.child,
  });

  final double progress;
  final double offset;
  final Widget child;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: progress,
    child: Transform.translate(
      offset: Offset(0, offset * (1 - progress)),
      child: child,
    ),
  );
}

/// Dibuja un fotograma del símbolo con cotas para el progreso `t` (0–1).
class SplashPainter extends CustomPainter {
  SplashPainter(this.t);

  final double t;

  // Centro de las flechas: crecen desde ahí, como en el canvas.
  static const _arrowsCenter = Offset(124.1, 71.45);

  @override
  void paint(Canvas canvas, Size size) {
    const bounds = A2CMark.cotasBounds;
    final s = math.min(size.width / bounds.width, size.height / bounds.height);
    canvas.save();
    canvas.translate(
      (size.width - bounds.width * s) / 2,
      (size.height - bounds.height * s) / 2,
    );
    canvas.scale(s);
    canvas.translate(-bounds.left, -bounds.top);

    final stroke = Paint()
      ..color = A2CColors.ink
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;
    void partial((Offset, Offset) line, double p, double width) {
      if (p <= 0) return;
      final (a, b) = line;
      canvas.drawLine(a, Offset.lerp(a, b, p)!, stroke..strokeWidth = width);
    }

    for (var i = 0; i < A2CMark.thinLines.length; i++) {
      partial(
        A2CMark.thinLines[i],
        SplashTimeline.thinLine(t, i),
        A2CMark.thinWidth,
      );
    }
    for (var i = 0; i < A2CMark.dimLines.length; i++) {
      partial(
        A2CMark.dimLines[i],
        SplashTimeline.dimLine(t, i),
        A2CMark.dimWidth,
      );
    }

    final arrows = SplashTimeline.arrows(t);
    if (arrows > 0) {
      final scale = lerpDouble(0.6, 1, arrows)!;
      canvas.save();
      canvas.translate(_arrowsCenter.dx, _arrowsCenter.dy);
      canvas.scale(scale);
      canvas.translate(-_arrowsCenter.dx, -_arrowsCenter.dy);
      final fill = Paint()..color = A2CColors.ink.withValues(alpha: arrows);
      for (final (tip, dir) in A2CMark.arrows) {
        canvas.drawPath(A2CMark.arrowPath(tip, dir), fill);
      }
      canvas.restore();
    }

    final ink = Paint()..color = A2CColors.ink;
    _rise(canvas, A2CMark.bladeLeft(), ink, SplashTimeline.bladeLeft(t), 160);
    _rise(
      canvas,
      A2CMark.bladeRight(),
      ink,
      SplashTimeline.bladeRight(t),
      119.33,
    );

    final two = SplashTimeline.two(t);
    if (two > 0) {
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(111, -1, lerpDouble(111, 252, two)!, 161));
      canvas.drawPath(A2CMark.two(), Paint()..color = A2CColors.brandYellow);
      canvas.restore();
    }
    canvas.restore();
  }

  /// La pieza sube 10 u mientras se descubre desde su base.
  void _rise(Canvas canvas, Path path, Paint paint, double p, double bottom) {
    if (p <= 0) return;
    canvas.save();
    canvas.translate(0, 10 * (1 - p));
    canvas.clipRect(Rect.fromLTRB(-1, bottom * (1 - p), 160, bottom + 1));
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(SplashPainter oldDelegate) => oldDelegate.t != t;
}
