import 'package:flutter/material.dart';

import '../../../core/theme/a2c_colors.dart';
import '../../../core/theme/a2c_dimens.dart';
import '../../../core/theme/a2c_typography.dart';
import '../../../shared/widgets/a2c_logo.dart';

/// Cotas del logo como recurso gráfico de la cabecera negra del ingreso
/// (canvas "Ingreso v2"): un plano tenue detrás del título.
class LoginHeaderPainter extends CustomPainter {
  const LoginHeaderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    A2CMark.fitInto(canvas, size, A2CMark.cotasBounds);
    A2CMark.paintCotas(canvas, A2CColors.onInk.withValues(alpha: 0.13));
    canvas.restore();
  }

  @override
  bool shouldRepaint(LoginHeaderPainter oldDelegate) => false;
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
