import 'package:flutter/material.dart';

import 'a2c_colors.dart';

/// Escala tipográfica Geist (docs/09_DESIGN_SYSTEM.md §4).
abstract final class A2CText {
  static const family = 'Geist';
  static const monoFamily = 'GeistMono';
  static const brandFamily = 'Montserrat';

  /// "A2 CONSTRUCTORA" del logotipo: Montserrat Black (docs/09 §2).
  static const wordmark = TextStyle(
    fontFamily: brandFamily,
    fontWeight: FontWeight.w900,
    fontVariations: [FontVariation('wght', 900)],
    height: 1,
    color: A2CColors.ink,
  );

  /// Lema "TU VISIÓN · NUESTRA EJECUCIÓN": Montserrat Medium espaciada.
  static const tagline = TextStyle(
    fontFamily: brandFamily,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
    letterSpacing: 4,
    height: 1,
    color: Color(0xFF3A3A3A),
  );

  static const display = TextStyle(
    fontFamily: family,
    fontSize: 34,
    height: 1.08,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.85,
    color: A2CColors.ink,
  );
  static const headline = TextStyle(
    fontFamily: family,
    fontSize: 30,
    height: 1.15,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.6,
    color: A2CColors.ink,
  );
  static const title = TextStyle(
    fontFamily: family,
    fontSize: 18,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: A2CColors.ink,
  );
  static const body = TextStyle(
    fontFamily: family,
    fontSize: 16,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: A2CColors.ink,
  );
  static const bodyStrong = TextStyle(
    fontFamily: family,
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w600,
    color: A2CColors.ink,
  );
  static const label = TextStyle(
    fontFamily: family,
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w500,
    color: A2CColors.inkSecondary,
  );
  static const caption = TextStyle(
    fontFamily: family,
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w500,
    color: A2CColors.inkSecondary,
  );
  static const overline = TextStyle(
    fontFamily: family,
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.7,
    color: A2CColors.inkSecondary,
  );
  static const metric = TextStyle(
    fontFamily: family,
    fontSize: 48,
    height: 1,
    fontWeight: FontWeight.w300,
    letterSpacing: -1.44,
    color: A2CColors.ink,
  );
  static const code = TextStyle(
    fontFamily: monoFamily,
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w500,
    color: A2CColors.inkSecondary,
  );

  static TextTheme textTheme() => const TextTheme(
    displaySmall: display,
    headlineMedium: headline,
    titleLarge: title,
    titleMedium: bodyStrong,
    bodyLarge: body,
    bodyMedium: body,
    bodySmall: caption,
    labelLarge: bodyStrong,
    labelMedium: label,
    labelSmall: caption,
  );
}
