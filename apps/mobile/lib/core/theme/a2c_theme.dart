import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'a2c_colors.dart';
import 'a2c_dimens.dart';
import 'a2c_typography.dart';

/// Tema único de la app. Ningún widget usa colores literales: todo sale de aquí
/// o de [A2CColors] (RNF-MA-05).
abstract final class A2CTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: A2CColors.brandYellow,
      onPrimary: A2CColors.onYellow,
      primaryContainer: A2CColors.brandYellowSoft,
      onPrimaryContainer: A2CColors.ink,
      secondary: A2CColors.ink,
      onSecondary: A2CColors.onInk,
      surface: A2CColors.background,
      onSurface: A2CColors.ink,
      onSurfaceVariant: A2CColors.inkSecondary,
      surfaceContainerHighest: A2CColors.surfaceStrong,
      outline: A2CColors.borderStrong,
      outlineVariant: A2CColors.border,
      error: A2CColors.error,
      onError: A2CColors.onInk,
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: A2CColors.borderStrong),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: A2CColors.background,
      fontFamily: A2CText.family,
      textTheme: A2CText.textTheme(),
      splashFactory: InkSparkle.splashFactory,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: const AppBarTheme(
        backgroundColor: A2CColors.background,
        foregroundColor: A2CColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: A2CText.title,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: A2CColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        hintStyle: A2CText.body.copyWith(color: A2CColors.inkTertiary),
        labelStyle: A2CText.label,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: A2CColors.ink, width: 2),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: A2CColors.error),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: A2CColors.ink,
        contentTextStyle: A2CText.bodyStrong.copyWith(color: A2CColors.onInk),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(A2CRadii.md),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: A2CColors.border,
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: A2CColors.ink,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
