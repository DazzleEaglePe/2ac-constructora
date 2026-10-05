import 'package:flutter/animation.dart';

/// Curva principal de la animación del logo: `cubic-bezier(.7, 0, .2, 1)` (docs/09 §8).
const splashCurve = Cubic(0.7, 0, 0.2, 1);

/// Interpola un valor entre paradas `(progreso 0–1, valor)` aplicando [curve]
/// dentro de cada tramo. Fuera del rango se mantiene el extremo.
double keyframe(
  double t,
  List<(double, double)> stops, {
  Curve curve = splashCurve,
}) {
  if (t <= stops.first.$1) return stops.first.$2;
  for (var i = 0; i < stops.length - 1; i++) {
    final (t0, v0) = stops[i];
    final (t1, v1) = stops[i + 1];
    if (t <= t1) {
      if (t1 == t0) return v1;
      final local = curve.transform(((t - t0) / (t1 - t0)).clamp(0, 1));
      return v0 + (v1 - v0) * local;
    }
  }
  return stops.last.$2;
}

/// Valor escalonado (cortes secos): devuelve el valor del último tramo iniciado.
T step<T>(double t, List<(double, T)> stops) {
  var value = stops.first.$2;
  for (final (start, v) in stops) {
    if (t >= start) value = v;
  }
  return value;
}
