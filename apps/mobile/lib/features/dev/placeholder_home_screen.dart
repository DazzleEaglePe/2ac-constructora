import 'package:flutter/material.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/theme/a2c_dimens.dart';
import '../../core/theme/a2c_typography.dart';
import '../../shared/widgets/a2c_logo.dart';

/// Pantalla provisoria de staging/prod hasta el Sprint 1 (splash, onboarding, ingreso).
class PlaceholderHomeScreen extends StatelessWidget {
  const PlaceholderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(A2CSpace.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const A2CLogo(height: 56),
              const SizedBox(height: A2CSpace.xl),
              Text(l10n.brandName.toUpperCase(), style: A2CText.overline),
              const SizedBox(height: A2CSpace.sm),
              Text(l10n.tagline, style: A2CText.label),
            ],
          ),
        ),
      ),
    );
  }
}
