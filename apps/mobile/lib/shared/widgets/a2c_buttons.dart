import 'package:flutter/material.dart';

import '../../core/theme/a2c_colors.dart';
import '../../core/theme/a2c_dimens.dart';
import '../../core/theme/a2c_typography.dart';

/// Botón principal: píldora amarilla con texto negro (docs/09 §7).
class A2CPrimaryButton extends StatelessWidget {
  const A2CPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: A2CColors.ink,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    return SizedBox(
      width: expand ? double.infinity : null,
      height: A2CSizes.primaryButtonHeight,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.pressed)
                ? A2CColors.brandYellowPressed
                : s.contains(WidgetState.disabled) && !loading
                ? A2CColors.brandYellow.withValues(alpha: 0.4)
                : A2CColors.brandYellow,
          ),
          foregroundColor: const WidgetStatePropertyAll(A2CColors.onYellow),
          textStyle: WidgetStatePropertyAll(
            A2CText.bodyStrong.copyWith(fontSize: 16),
          ),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          elevation: const WidgetStatePropertyAll(0),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 24),
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Botón secundario: píldora clara con borde.
class A2CSecondaryButton extends StatelessWidget {
  const A2CSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: expand ? double.infinity : null,
      height: A2CSizes.primaryButtonHeight,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon == null ? null : Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: A2CColors.ink,
          backgroundColor: A2CColors.surface,
          side: const BorderSide(color: A2CColors.borderStrong),
          shape: const StadiumBorder(),
          textStyle: A2CText.bodyStrong,
        ),
      ),
    );
  }
}

/// Botón circular de solo ícono. La etiqueta es obligatoria (lectores de pantalla).
class A2CIconButton extends StatelessWidget {
  const A2CIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: semanticLabel,
      icon: Icon(icon, size: 20, semanticLabel: semanticLabel),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(A2CSizes.iconButton),
        foregroundColor: A2CColors.ink,
        backgroundColor: A2CColors.surface,
        side: const BorderSide(color: A2CColors.border),
      ),
    );
  }
}

/// Botón flotante amarillo para la acción principal de una lista.
class A2CFab extends StatelessWidget {
  const A2CFab({
    super.key,
    required this.semanticLabel,
    required this.onPressed,
    this.icon,
  });

  final String semanticLabel;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox.square(
        dimension: A2CSizes.fab,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x73F2B200),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: onPressed,
            tooltip: semanticLabel,
            elevation: 0,
            shape: const CircleBorder(),
            backgroundColor: A2CColors.brandYellow,
            foregroundColor: A2CColors.ink,
            child: Icon(icon ?? Icons.add_rounded, size: 28),
          ),
        ),
      ),
    );
  }
}
