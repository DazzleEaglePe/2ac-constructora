import 'package:a2c_inventario/features/welcome/a2c_splash_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la línea de tiempo empieza vacía y termina completa', () {
    expect(SplashTimeline.thinLine(0, 0), 0);
    expect(SplashTimeline.bladeLeft(0), 0);
    expect(SplashTimeline.two(0), 0);
    expect(SplashTimeline.wordmark(0), 0);
    for (var i = 0; i < 14; i++) {
      expect(SplashTimeline.thinLine(1, i), 1);
    }
    for (var i = 0; i < 6; i++) {
      expect(SplashTimeline.dimLine(1, i), 1);
    }
    expect(SplashTimeline.arrows(1), 1);
    expect(SplashTimeline.two(1), 1);
    expect(SplashTimeline.tagline(1), 1);
  });

  test('sigue el orden del canvas: cotas, hojas de la A, el 2 y el texto', () {
    double at(double seconds) => seconds / SplashTimeline.total;
    // A 1,2 s las cotas ya están, la A empieza y el 2 todavía no.
    expect(SplashTimeline.thinLine(at(1.2), 0), 1);
    expect(SplashTimeline.bladeLeft(at(1.2)), greaterThan(0));
    expect(SplashTimeline.two(at(1.2)), 0);
    // A 2,45 s el monograma está completo y el nombre recién entra.
    expect(SplashTimeline.two(at(2.45)), 1);
    expect(SplashTimeline.wordmark(at(2.45)), lessThan(0.5));
    expect(SplashTimeline.tagline(at(2.45)), 0);
  });

  testWidgets('avisa al terminar la animación', (tester) async {
    var done = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: A2CSplashAnimation(onComplete: () => done = true),
          ),
        ),
      ),
    );
    await tester.pump(A2CSplashAnimation.duration ~/ 2);
    expect(done, isFalse);
    await tester.pump(A2CSplashAnimation.duration);
    expect(done, isTrue);
  });

  testWidgets(
    'con "reducir movimiento" muestra el final y avisa de inmediato',
    (tester) async {
      var done = false;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: A2CSplashAnimation(onComplete: () => done = true),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(done, isTrue);
    },
  );
}
