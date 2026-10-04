/// Radios, espaciado y tamaños táctiles (docs/09_DESIGN_SYSTEM.md §5).
abstract final class A2CRadii {
  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 22.0;
  static const xl = 28.0;
  static const pill = 999.0;
}

abstract final class A2CSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;

  /// Margen lateral de las pantallas.
  static const screen = 16.0;
}

abstract final class A2CSizes {
  /// Área táctil mínima (48 dp en Android, ≥ 44 pt en iOS).
  static const minTouch = 48.0;
  static const primaryButtonHeight = 54.0;
  static const fieldHeight = 52.0;
  static const iconButton = 44.0;
  static const fab = 60.0;
}
