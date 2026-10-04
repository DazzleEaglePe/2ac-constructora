import 'package:flutter/painting.dart';

/// Tokens de color de la marca Constructora A2C (docs/09_DESIGN_SYSTEM.md §3).
///
/// Regla: nunca texto amarillo sobre blanco. El amarillo va como relleno con
/// texto negro, o como texto sobre negro.
abstract final class A2CColors {
  static const brandYellow = Color(0xFFFFC20E);
  static const brandYellowPressed = Color(0xFFF2B200);
  static const brandYellowSoft = Color(0xFFFFF3C4);

  static const ink = Color(0xFF0A0A0A);
  static const inkSecondary = Color(0xFF5C5C5C);
  static const inkTertiary = Color(0xFF767676);
  static const goldText = Color(0xFF7A5A00);

  static const background = Color(0xFFFFFFFF);
  static const backgroundAlt = Color(0xFFF6F6F4);
  static const surface = Color(0x0A000000); // negro 4 %
  static const surfaceStrong = Color(0xFFF4F4F4);
  static const border = Color(0x17000000); // negro 9 %
  static const borderStrong = Color(0x1F000000); // negro 12 %

  static const onYellow = ink;
  static const onInk = Color(0xFFFFFFFF);
  static const onInkSecondary = Color(0xFFBDBDBD);
  static const navInactive = Color(0xFFA3A3A3);

  static const retiredText = Color(0xFF6B6B6B);
  static const retiredBorder = Color(0xFFA3A3A3);
  static const error = Color(0xFFB42318);

  /// Series de gráficos (se distinguen por luminosidad).
  static const chartSeries = [ink, Color(0xFF8A8A8A), Color(0xFFD4D4D4)];
}
