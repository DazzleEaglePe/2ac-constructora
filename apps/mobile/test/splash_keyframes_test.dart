import 'package:a2c_inventario/core/theme/a2c_colors.dart';
import 'package:a2c_inventario/features/welcome/a2c_splash_animation.dart';
import 'package:a2c_inventario/features/welcome/keyframes.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keyframe interpola entre paradas y mantiene los extremos', () {
    const stops = [(0.2, 0.0), (0.4, 10.0)];
    expect(keyframe(0.0, stops), 0);
    expect(keyframe(1.0, stops), 10);
    expect(keyframe(0.3, stops, curve: Curves.linear), closeTo(5, 1e-9));
  });

  test('step aplica cortes secos', () {
    const stops = [(0.0, 'a'), (0.5, 'b')];
    expect(step(0.49, stops), 'a');
    expect(step(0.5, stops), 'b');
  });

  test('el fondo sigue la línea de tiempo de docs/09 §8', () {
    expect(SplashPainter.backgroundAt(0.05), const Color(0xFFE6E6E3));
    expect(SplashPainter.backgroundAt(0.15), A2CColors.brandYellow);
    expect(SplashPainter.backgroundAt(0.30), A2CColors.ink);
    expect(SplashPainter.backgroundAt(0.45), const Color(0xFFFFFFFF));
    expect(SplashPainter.backgroundAt(0.70), const Color(0xFFF3F0E8));
    expect(SplashPainter.backgroundAt(0.95), const Color(0xFFE6E6E3));
  });
}
