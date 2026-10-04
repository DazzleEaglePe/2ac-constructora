import 'package:flutter/material.dart';

import '../../core/theme/a2c_colors.dart';
import '../../core/theme/a2c_dimens.dart';
import '../../core/theme/a2c_typography.dart';

/// Tarjeta base: superficie clara con borde fino y radio 22.
class A2CCard extends StatelessWidget {
  const A2CCard({super.key, required this.child, this.onTap, this.padding});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(A2CRadii.lg);
    return Material(
      color: A2CColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: A2CColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(18),
          child: child,
        ),
      ),
    );
  }
}

/// Tarjeta destacada negra con cifra amarilla (Almacén, resumen de obra).
/// Una sola por bloque (docs/09 §3).
class HighlightCard extends StatelessWidget {
  const HighlightCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    this.subtitle,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final String value;
  final String unit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: A2CColors.ink,
      borderRadius: BorderRadius.circular(A2CRadii.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: A2CText.title.copyWith(color: A2CColors.onInk),
                    ),
                  ),
                  if (onTap != null)
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: A2CColors.brandYellow,
                      foregroundColor: A2CColors.ink,
                      child: Icon(Icons.north_east_rounded, size: 16),
                    ),
                ],
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: A2CText.label.copyWith(
                    color: A2CColors.onInkSecondary,
                  ),
                ),
              const SizedBox(height: A2CSpace.lg),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: value),
                    TextSpan(
                      text: '  $unit',
                      style: A2CText.label.copyWith(
                        color: A2CColors.onInkSecondary,
                      ),
                    ),
                  ],
                ),
                style: A2CText.metric.copyWith(color: A2CColors.brandYellow),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
