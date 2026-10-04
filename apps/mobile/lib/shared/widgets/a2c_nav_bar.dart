import 'package:flutter/material.dart';

import '../../core/theme/a2c_colors.dart';
import '../../core/theme/a2c_dimens.dart';
import '../../core/theme/a2c_typography.dart';

class A2CNavItem {
  const A2CNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Barra de navegación flotante: píldora negra; el destino activo es una píldora
/// amarilla con ícono y texto negros (debe contrastar con la barra, docs/09 §7).
class A2CNavBar extends StatelessWidget {
  const A2CNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<A2CNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: A2CColors.ink,
          borderRadius: BorderRadius.circular(A2CRadii.pill),
          boxShadow: const [
            BoxShadow(
              color: Color(0x38000000),
              blurRadius: 30,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                flex: i == currentIndex ? 16 : 10,
                child: _NavButton(
                  item: items[i],
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final A2CNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? A2CColors.ink : A2CColors.navInactive;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(A2CRadii.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: 52,
          decoration: BoxDecoration(
            color: selected ? A2CColors.brandYellow : Colors.transparent,
            borderRadius: BorderRadius.circular(A2CRadii.pill),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: selected ? 20 : 22, color: fg),
              if (selected) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    style: A2CText.bodyStrong.copyWith(color: fg, fontSize: 14),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
