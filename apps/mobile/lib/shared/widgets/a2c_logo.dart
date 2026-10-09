import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/a2c_colors.dart';

/// Geometría del monograma "Cota" de A2 Constructora (docs/09 §2, anexo A),
/// en unidades del manual: el monograma mide 250,8 × 160 u y sus cotas ocupan
/// la caja [cotasBounds]. Es la misma geometría del Illustrator
/// (PROPUESTAS_AI · "02 - Cota") y del canvas de diseño.
abstract final class A2CMark {
  static const width = 250.8;
  static const height = 160.0;
  static const aspectRatio = width / height;

  /// Caja del símbolo con cotas (viewBox del manual).
  static const cotasBounds = Rect.fromLTWH(-40, -54, 330, 247);

  /// Hoja izquierda de la A.
  static Path bladeLeft() => Path()
    ..moveTo(0, 160)
    ..lineTo(85.4, 0)
    ..lineTo(85.4, 69.13)
    ..lineTo(36.9, 160)
    ..close();

  /// Hoja derecha de la A: se corta en paralelo a la diagonal del 2.
  static Path bladeRight() => Path()
    ..moveTo(88.1, 0)
    ..lineTo(139.07, 98.97)
    ..lineTo(112.05, 119.33)
    ..lineTo(88.1, 72.82)
    ..close();

  /// El 2: remate superior plano, panza de dos radios, diagonal a 37° y barra.
  static Path two() {
    const deg = math.pi / 180;
    Rect circle(double x, double y, double r) =>
        Rect.fromCircle(center: Offset(x, y), radius: r);
    return Path()
      ..moveTo(139.2, 2.2)
      ..lineTo(212.7, 2.2)
      ..arcTo(circle(212.7, 40.3, 38.1), -90 * deg, 90 * deg, false)
      ..lineTo(250.8, 47)
      ..arcTo(circle(221, 47, 29.8), 0, 53 * deg, false)
      ..lineTo(162.63, 128.3)
      ..lineTo(243.4, 128.3)
      ..lineTo(243.4, 160)
      ..lineTo(112.28, 160)
      ..lineTo(112.28, 128.3)
      ..lineTo(214.99, 50.9)
      ..arcTo(circle(210.9, 45.47, 6.8), 53 * deg, -53 * deg, false)
      ..lineTo(217.7, 41.3)
      ..arcTo(circle(208.8, 41.3, 8.9), 0, -90 * deg, false)
      ..lineTo(139.2, 32.4)
      ..close();
  }

  /// Líneas finas de las cotas: marco de extensión, línea base y marcas.
  static const thinLines = <(Offset, Offset)>[
    (Offset(0, -50), Offset(0, 189)),
    (Offset(254.6, -4.2), Offset(254.6, 189)),
    (Offset(0, -4.2), Offset(286, -4.2)),
    (Offset(-37, -4.2), Offset(-6, -4.2)),
    (Offset(-37, 160.4), Offset(112.28, 160.4)),
    (Offset(254.6, 160.4), Offset(286, 160.4)),
    (Offset(230.2, -50), Offset(230.2, 3.3)),
    (Offset(132.3, -13), Offset(132.3, -4.2)),
    (Offset(112.28, 160.4), Offset(112.28, 168.5)),
    (Offset(134, 166.6), Offset(250, 166.6)),
    (Offset(0, 160), Offset(-9.1, 177)),
    (Offset(-7, -20.8), Offset(6, -7.8)),
    (Offset(253.5, 7.1), Offset(286, 7.1)),
    (Offset(253.5, 147.6), Offset(286, 147.6)),
  ];

  /// Líneas de cota (más gruesas, con flechas).
  static const dimLines = <(Offset, Offset)>[
    (Offset(0, -34.5), Offset(230.2, -34.5)),
    (Offset(-21, -4.2), Offset(-21, 160.4)),
    (Offset(269.2, -24), Offset(269.2, -4.2)),
    (Offset(269.2, 7.1), Offset(269.2, 147.6)),
    (Offset(269.2, 160.4), Offset(269.2, 180)),
    (Offset(0, 177.4), Offset(254.6, 177.4)),
  ];

  /// Flechas: punta y dirección hacia la que apuntan.
  static const arrows = <(Offset, Offset)>[
    (Offset(0, -34.5), Offset(-1, 0)),
    (Offset(230.2, -34.5), Offset(1, 0)),
    (Offset(-21, -4.2), Offset(0, -1)),
    (Offset(-21, 160.4), Offset(0, 1)),
    (Offset(269.2, -4.2), Offset(0, 1)),
    (Offset(269.2, 7.1), Offset(0, -1)),
    (Offset(269.2, 147.6), Offset(0, 1)),
    (Offset(269.2, 160.4), Offset(0, -1)),
    (Offset(0, 177.4), Offset(-1, 0)),
    (Offset(254.6, 177.4), Offset(1, 0)),
  ];

  static const thinWidth = 1.0;
  static const dimWidth = 1.5;

  static Path arrowPath(Offset tip, Offset dir) {
    const length = 13.0, halfWidth = 4.3;
    final base = tip - dir * length;
    final normal = Offset(-dir.dy, dir.dx) * halfWidth;
    return Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base.dx + normal.dx, base.dy + normal.dy)
      ..lineTo(base.dx - normal.dx, base.dy - normal.dy)
      ..close();
  }

  /// Dibuja las cotas completas (sin el monograma).
  static void paintCotas(Canvas canvas, Color color) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;
    for (final (a, b) in thinLines) {
      canvas.drawLine(a, b, stroke..strokeWidth = thinWidth);
    }
    for (final (a, b) in dimLines) {
      canvas.drawLine(a, b, stroke..strokeWidth = dimWidth);
    }
    final fill = Paint()..color = color;
    for (final (tip, dir) in arrows) {
      canvas.drawPath(arrowPath(tip, dir), fill);
    }
  }

  /// Ajusta [bounds] dentro de [size] con escala uniforme, alineado a la
  /// izquierda y centrado en vertical. Deja el lienzo en unidades del manual.
  static void fitInto(Canvas canvas, Size size, Rect bounds) {
    final s = math.min(size.width / bounds.width, size.height / bounds.height);
    canvas.translate(0, (size.height - bounds.height * s) / 2);
    canvas.scale(s);
    canvas.translate(-bounds.left, -bounds.top);
  }
}

/// Símbolo de A2 Constructora. Único punto de uso del logo en la app
/// (docs/09 §2). Con [cotas] incluye las líneas de medición del manual; sin
/// ellas es la versión simplificada para tamaños pequeños.
class A2CLogo extends StatelessWidget {
  const A2CLogo({
    super.key,
    this.height = 40,
    this.onDark = false,
    this.cotas = false,
  });

  final double height;

  /// Sobre fondo negro, la A y las cotas pasan a blanco.
  final bool onDark;
  final bool cotas;

  static const aspectRatio = A2CMark.aspectRatio;

  @override
  Widget build(BuildContext context) {
    final bounds = cotas
        ? A2CMark.cotasBounds
        : const Rect.fromLTWH(0, 0, A2CMark.width, A2CMark.height);
    return Semantics(
      label: 'A2 Constructora',
      image: true,
      child: CustomPaint(
        size: Size(height * bounds.width / bounds.height, height),
        painter: A2CLogoPainter(
          inkColor: onDark ? A2CColors.onInk : A2CColors.ink,
          accentColor: A2CColors.brandYellow,
          cotas: cotas,
        ),
      ),
    );
  }
}

class A2CLogoPainter extends CustomPainter {
  const A2CLogoPainter({
    required this.inkColor,
    required this.accentColor,
    this.cotas = false,
  });

  final Color inkColor;
  final Color accentColor;
  final bool cotas;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    A2CMark.fitInto(
      canvas,
      size,
      cotas
          ? A2CMark.cotasBounds
          : const Rect.fromLTWH(0, 0, A2CMark.width, A2CMark.height),
    );
    if (cotas) A2CMark.paintCotas(canvas, inkColor);
    final ink = Paint()..color = inkColor;
    canvas.drawPath(A2CMark.bladeLeft(), ink);
    canvas.drawPath(A2CMark.bladeRight(), ink);
    canvas.drawPath(A2CMark.two(), Paint()..color = accentColor);
    canvas.restore();
  }

  @override
  bool shouldRepaint(A2CLogoPainter old) =>
      old.inkColor != inkColor ||
      old.accentColor != accentColor ||
      old.cotas != cotas;
}
