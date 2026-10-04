import 'package:flutter/material.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/theme/a2c_colors.dart';
import '../../core/theme/a2c_dimens.dart';
import '../../core/theme/a2c_typography.dart';
import '../domain/asset_status.dart';

/// Chip de activo con cantidad ("Palas ×2"). La cantidad va en dorado oscuro,
/// nunca en amarillo, para que se lea sobre fondo claro.
class A2CChip extends StatelessWidget {
  const A2CChip({
    super.key,
    required this.label,
    this.quantity,
    this.onDark = false,
  });

  final String label;
  final int? quantity;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? A2CColors.onInk : A2CColors.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: onDark ? const Color(0x29FFFFFF) : const Color(0x0F000000),
        borderRadius: BorderRadius.circular(A2CRadii.pill),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: label),
            if (quantity != null)
              TextSpan(
                text: ' ×$quantity',
                style: A2CText.code.copyWith(
                  color: onDark ? A2CColors.brandYellow : A2CColors.goldText,
                ),
              ),
          ],
        ),
        style: A2CText.label.copyWith(color: fg, fontSize: 13),
      ),
    );
  }
}

/// Píldora de estado del activo (docs/09 §3). Se distinguen por forma además de color.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final AssetStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, bg, fg, border) = switch (status) {
      AssetStatus.operativo => (
        l10n.statusOperational,
        A2CColors.ink,
        A2CColors.onInk,
        null,
      ),
      AssetStatus.mantenimiento => (
        l10n.statusMaintenance,
        A2CColors.brandYellow,
        A2CColors.ink,
        null,
      ),
      AssetStatus.baja => (
        l10n.statusRetired,
        Colors.transparent,
        A2CColors.retiredText,
        A2CColors.retiredBorder,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: ShapeDecoration(
        color: bg,
        shape: StadiumBorder(
          side: border == null ? BorderSide.none : BorderSide(color: border),
        ),
      ),
      child: Text(
        label,
        style: A2CText.caption.copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
