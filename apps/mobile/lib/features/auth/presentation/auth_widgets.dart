import 'package:flutter/material.dart';

import '../../../core/theme/a2c_colors.dart';
import '../../../core/theme/a2c_dimens.dart';
import '../../../core/theme/a2c_typography.dart';

/// Ícono A2C de 76 px: cuadrado negro con el "2" amarillo.
class A2CAppIcon extends StatelessWidget {
  const A2CAppIcon({super.key, this.size = 76});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: A2CColors.ink,
      borderRadius: BorderRadius.circular(size * 0.29),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1F000000),
          blurRadius: 40,
          offset: Offset(0, 16),
        ),
      ],
    ),
    child: Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'A'),
          WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: Text(
              '2',
              style: A2CText.display.copyWith(
                fontSize: size * 0.2,
                color: A2CColors.brandYellow,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const TextSpan(text: 'C'),
        ],
      ),
      style: A2CText.display.copyWith(
        fontSize: size * 0.37,
        color: A2CColors.onInk,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
      ),
      semanticsLabel: 'A2C',
    ),
  );
}

/// Fondo del encabezado del ingreso: brillo amarillo, siluetas de edificios y
/// franja de seguridad (docs/09 §9).
class LoginHeroPainter extends CustomPainter {
  const LoginHeroPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.6),
          radius: 0.9,
          colors: [
            A2CColors.brandYellow.withValues(alpha: 0.22),
            A2CColors.brandYellow.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );

    final w = size.width / 390;
    final buildings = [
      (18.0, 190.0, 54.0, const Color(0xFFEFEFEC)),
      (82.0, 140.0, 62.0, const Color(0xFFE7E7E3)),
      (250.0, 120.0, 64.0, const Color(0xFFE7E7E3)),
      (324.0, 180.0, 54.0, const Color(0xFFEFEFEC)),
    ];
    final windows = Paint()..color = const Color(0x0F0A0A0A);
    for (final (x, top, width, color) in buildings) {
      final r = RRect.fromRectAndRadius(
        Rect.fromLTRB(x * w, top, (x + width) * w, size.height + 20),
        const Radius.circular(10),
      );
      canvas.drawRRect(r, Paint()..color = color);
      for (var y = top + 10; y < size.height; y += 14) {
        canvas.drawRect(Rect.fromLTWH(x * w, y, width * w, 5), windows);
      }
    }
    // Desvanecido hacia el fondo de la pantalla.
    final fade = Rect.fromLTWH(
      0,
      size.height * 0.5,
      size.width,
      size.height * 0.5,
    );
    canvas.drawRect(
      fade,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00F6F6F4), A2CColors.backgroundAlt],
        ).createShader(fade),
    );
  }

  @override
  bool shouldRepaint(LoginHeroPainter oldDelegate) => false;
}

/// Franja de seguridad amarilla y negra.
class SafetyStripe extends StatelessWidget {
  const SafetyStripe({super.key, this.height = 8});

  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: const CustomPaint(painter: _StripePainter()),
  );
}

class _StripePainter extends CustomPainter {
  const _StripePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..color = A2CColors.ink);
    final p = Paint()
      ..color = A2CColors.brandYellow
      ..strokeWidth = 12;
    for (var x = -size.height; x < size.width + size.height; x += 24 * 1.4142) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), p);
    }
  }

  @override
  bool shouldRepaint(_StripePainter oldDelegate) => false;
}

/// Mensaje de error en línea (no solo color: ícono + texto).
class InlineError extends StatelessWidget {
  const InlineError({super.key, required this.message, this.detail});

  final String message;
  final String? detail;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(A2CRadii.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: A2CColors.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: A2CText.bodyStrong.copyWith(
                    color: const Color(0xFF7A1A12),
                  ),
                ),
                if (detail != null)
                  Text(
                    detail!,
                    style: A2CText.caption.copyWith(
                      color: const Color(0xFF7A1A12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
