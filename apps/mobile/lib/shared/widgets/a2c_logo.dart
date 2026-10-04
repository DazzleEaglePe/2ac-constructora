import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/a2c_colors.dart';

/// Monograma A2C (provisorio hasta el rebranding). Único punto de reemplazo del
/// logo en toda la app (docs/09 §2). Trazados en docs/09, anexo A (viewBox 320×120).
class A2CLogo extends StatelessWidget {
  const A2CLogo({super.key, this.height = 40, this.onDark = false});

  final double height;

  /// Sobre fondo negro, la A y la C pasan a blanco.
  final bool onDark;

  static const aspectRatio = 320 / 120;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Constructora A2C',
      image: true,
      child: CustomPaint(
        size: Size(height * aspectRatio, height),
        painter: A2CLogoPainter(
          inkColor: onDark ? A2CColors.onInk : A2CColors.ink,
          accentColor: A2CColors.brandYellow,
        ),
      ),
    );
  }
}

class A2CLogoPainter extends CustomPainter {
  const A2CLogoPainter({required this.inkColor, required this.accentColor});

  final Color inkColor;
  final Color accentColor;

  static Path letterA() => Path()
    ..fillType = PathFillType.evenOdd
    ..addPolygon(const [
      Offset(0, 120), Offset(44, 0), Offset(84, 0), Offset(128, 120), //
      Offset(96, 120), Offset(86, 92), Offset(42, 92), Offset(32, 120),
    ], true)
    ..addPolygon(const [Offset(50, 68), Offset(78, 68), Offset(64, 28)], true);

  static Path digitTwo() => Path()
    ..addPolygon(const [
      Offset(136, 0), Offset(224, 0), Offset(224, 70), Offset(170, 70), //
      Offset(170, 94), Offset(224, 94), Offset(224, 120), Offset(136, 120),
      Offset(136, 50), Offset(190, 50), Offset(190, 26), Offset(136, 26),
    ], true);

  static Path letterC() => Path()
    ..addPolygon(const [
      Offset(320, 0), Offset(232, 0), Offset(232, 120), Offset(320, 120), //
      Offset(320, 92), Offset(262, 92), Offset(262, 28), Offset(320, 28),
    ], true);

  @override
  void paint(Canvas canvas, Size size) {
    // Escala uniforme: si el padre fuerza otro ancho (p. ej., un ListView), el
    // monograma conserva su proporción y se alinea a la izquierda.
    final scale = math.min(size.width / 320, size.height / 120);
    canvas.save();
    canvas.translate(0, (size.height - 120 * scale) / 2);
    canvas.scale(scale);
    final ink = Paint()..color = inkColor;
    canvas.drawPath(letterA(), ink);
    canvas.drawPath(digitTwo(), Paint()..color = accentColor);
    canvas.drawPath(letterC(), ink);
    canvas.restore();
  }

  @override
  bool shouldRepaint(A2CLogoPainter old) =>
      old.inkColor != inkColor || old.accentColor != accentColor;
}
