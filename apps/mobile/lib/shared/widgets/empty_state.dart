import 'package:flutter/material.dart';

import '../../core/theme/a2c_colors.dart';
import '../../core/theme/a2c_dimens.dart';
import '../../core/theme/a2c_typography.dart';
import 'a2c_buttons.dart';

/// Estado vacío o de error: ícono + texto + acción (docs/08 §4).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: A2CColors.surface,
      borderRadius: BorderRadius.circular(A2CRadii.lg),
      border: Border.all(color: A2CColors.border),
    ),
    child: Column(
      children: [
        Semantics(
          container: true,
          liveRegion: true,
          label: '$title. $message',
          child: ExcludeSemantics(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: A2CColors.brandYellowSoft,
                  foregroundColor: A2CColors.ink,
                  child: Icon(icon),
                ),
                const SizedBox(height: 12),
                Text(title, style: A2CText.title, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: A2CText.label.copyWith(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 16),
          A2CSecondaryButton(
            label: actionLabel!,
            onPressed: onAction,
            expand: false,
          ),
        ],
      ],
    ),
  );
}
