import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/preferences.dart';
import '../../core/theme/a2c_colors.dart';
import '../../core/theme/a2c_dimens.dart';
import '../../core/theme/a2c_typography.dart';
import '../../shared/widgets/a2c_buttons.dart';
import '../../shared/widgets/a2c_chips.dart';

/// RF-BIE-03: onboarding de 3 pasos con tarjetas reales de la app (docs/09 §9).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;

  static const _titles = [
    'Cada herramienta\ny máquina, siempre\nubicada',
    'Mueve y asigna en\nsegundos, con registro\nde quién y cuándo',
    'Stock, estados e\nhistorial de cada\nactivo, en tiempo real',
  ];

  bool get _last => _index == _titles.length - 1;

  Future<void> _finish() async {
    await ref.read(onboardingSeenProvider.notifier).markSeen();
    if (mounted) context.go('/login');
  }

  void _next() => _last
      ? _finish()
      : _pages.nextPage(
          duration: const Duration(milliseconds: 450),
          curve: const Cubic(0.2, 0.8, 0.2, 1),
        );

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: _last ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton.icon(
                    onPressed: _last ? null : _finish,
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.chevron_right_rounded, size: 18),
                    label: const Text('Saltar'),
                    style: TextButton.styleFrom(
                      foregroundColor: A2CColors.ink,
                      textStyle: A2CText.bodyStrong,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  for (var i = 0; i < _titles.length; i++)
                    _OnboardingPage(
                      title: _titles[i],
                      illustration: _illustrations[i],
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                children: [
                  for (var i = 0; i < _titles.length; i++)
                    Semantics(
                      button: true,
                      selected: i == _index,
                      label: 'Ir al paso ${i + 1} de ${_titles.length}',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(A2CRadii.pill),
                        onTap: () => _pages.animateToPage(
                          i,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 14,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: i == _index ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _index
                                  ? A2CColors.ink
                                  : const Color(0xFFCFCFCF),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: A2CPrimaryButton(
                label: _last ? 'Comenzar' : 'Continuar',
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _illustrations = <Widget>[
    _StepLocation(),
    _StepMovement(),
    _StepControl(),
  ];
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.title, required this.illustration});

  final String title;
  final Widget illustration;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: FittedBox(
                child: SizedBox(width: 342, height: 400, child: illustration),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(title, style: A2CText.headline),
        ],
      ),
    );
  }
}

// ── Ilustraciones: tarjetas reales de la app ─────────────────────────────

class _Ghost extends StatelessWidget {
  const _Ghost({
    required this.left,
    required this.top,
    required this.width,
    required this.angle,
    required this.child,
  });

  final double left, top, width, angle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Positioned(
    left: left,
    top: top,
    width: width,
    child: Transform.rotate(
      angle: angle * 3.1415926 / 180,
      child: Opacity(
        opacity: 0.5,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 1.2, sigmaY: 1.2),
          child: _CardShell(color: const Color(0xFFF4F4F2), child: child),
        ),
      ),
    ),
  );
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.child,
    this.color = A2CColors.background,
    this.shadow = false,
  });

  final Widget child;
  final Color color;
  final bool shadow;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: A2CColors.border),
      boxShadow: shadow
          ? const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 50,
                offset: Offset(0, 24),
              ),
            ]
          : null,
    ),
    child: child,
  );
}

class _YellowNote extends StatelessWidget {
  const _YellowNote({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: A2CColors.brandYellow,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1F000000),
          blurRadius: 28,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: A2CText.caption.copyWith(color: A2CColors.ink)),
        Text(value, style: A2CText.title.copyWith(fontSize: 17)),
      ],
    ),
  );
}

class _StepLocation extends StatelessWidget {
  const _StepLocation();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _Ghost(
          left: 0,
          top: 40,
          width: 190,
          angle: -8,
          child: Text(
            'Edificio Los Álamos',
            style: A2CText.bodyStrong.copyWith(fontSize: 13),
          ),
        ),
        _Ghost(
          left: 170,
          top: 8,
          width: 170,
          angle: 7,
          child: Text(
            'Casa Morales',
            style: A2CText.bodyStrong.copyWith(fontSize: 13),
          ),
        ),
        Positioned(
          left: 20,
          top: 130,
          width: 300,
          child: _CardShell(
            shadow: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Obra Juan Ramírez',
                  style: A2CText.title.copyWith(fontSize: 16),
                ),
                const Text('Dueño: Juan Ramírez', style: A2CText.caption),
                const SizedBox(height: 12),
                const Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    A2CChip(label: 'Trompo', quantity: 1),
                    A2CChip(label: 'Palas', quantity: 2),
                    A2CChip(label: 'Pico', quantity: 4),
                  ],
                ),
                const Divider(height: 24),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('9 unidades', style: A2CText.caption),
                    Text('hace 12 min', style: A2CText.caption),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Positioned(
          right: 0,
          top: 310,
          child: _YellowNote(
            title: 'Almacén central',
            value: '31 uds disponibles',
          ),
        ),
      ],
    );
  }
}

class _StepMovement extends StatelessWidget {
  const _StepMovement();

  @override
  Widget build(BuildContext context) {
    Widget connector() => Container(
      width: 2,
      height: 30,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: const Color(0xFFC99600),
    );
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const ShapeDecoration(
            color: A2CColors.background,
            shape: StadiumBorder(
              side: BorderSide(color: A2CColors.borderStrong),
            ),
          ),
          child: Text(
            'Almacén central · 2 disponibles',
            style: A2CText.label.copyWith(color: A2CColors.ink),
          ),
        ),
        connector(),
        _CardShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('MOVIENDO · HER-0142', style: A2CText.code),
              const SizedBox(height: 6),
              Text(
                'Amoladora angular 4½"',
                style: A2CText.title.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    '−   1   +',
                    style: A2CText.title.copyWith(fontWeight: FontWeight.w300),
                  ),
                  const Spacer(),
                  const StatusBadgeOperativo(),
                ],
              ),
            ],
          ),
        ),
        connector(),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: A2CColors.brandYellow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: A2CColors.ink,
                foregroundColor: A2CColors.brandYellow,
                child: Icon(Icons.check_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Asignado a Obra Juan Ramírez',
                      style: A2CText.bodyStrong,
                    ),
                    Text(
                      'por Martín Ruiz · hoy 09:42',
                      style: A2CText.caption.copyWith(
                        color: const Color(0xFF4A3A00),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Píldora "Operativo" sin depender de la localización (ilustración estática).
class StatusBadgeOperativo extends StatelessWidget {
  const StatusBadgeOperativo({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: const ShapeDecoration(
      color: A2CColors.ink,
      shape: StadiumBorder(),
    ),
    child: Text(
      'Operativo',
      style: A2CText.caption.copyWith(
        color: A2CColors.onInk,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _StepControl extends StatelessWidget {
  const _StepControl();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _Ghost(
          left: 40,
          top: 0,
          width: 250,
          angle: -3,
          child: Text(
            'Edificio Los Álamos · 10 uds',
            style: A2CText.bodyStrong.copyWith(fontSize: 13),
          ),
        ),
        Positioned(
          left: 10,
          top: 60,
          width: 320,
          child: _CardShell(
            shadow: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Unidades en obra', style: A2CText.caption),
                    Text(
                      '+4 esta semana',
                      style: A2CText.caption.copyWith(
                        color: const Color(0xFF3F6B00),
                      ),
                    ),
                  ],
                ),
                Text('23', style: A2CText.metric.copyWith(fontSize: 40)),
                const SizedBox(height: 8),
                const SizedBox(
                  height: 90,
                  width: double.infinity,
                  child: CustomPaint(painter: _ChartPainter()),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 30,
          child: Transform.rotate(
            angle: -0.07,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const ShapeDecoration(
                color: A2CColors.background,
                shape: StadiumBorder(
                  side: BorderSide(color: A2CColors.borderStrong),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'En mantenimiento ',
                    style: A2CText.label.copyWith(color: A2CColors.ink),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 1,
                    ),
                    decoration: const ShapeDecoration(
                      color: A2CColors.brandYellow,
                      shape: StadiumBorder(),
                    ),
                    child: Text(
                      '2',
                      style: A2CText.label.copyWith(color: A2CColors.ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Positioned(
          right: 0,
          top: 300,
          child: _YellowNote(
            title: 'Historial',
            value: 'Almacén → Obra · 1 ud',
          ),
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  const _ChartPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const pts = [0.9, 0.7, 0.78, 0.5, 0.62, 0.3, 0.44, 0.2, 0.34, 0.1];
    final line = Path();
    for (var i = 0; i < pts.length; i++) {
      final p = Offset(size.width * i / (pts.length - 1), size.height * pts[i]);
      i == 0 ? line.moveTo(p.dx, p.dy) : line.lineTo(p.dx, p.dy);
    }
    final area = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x8CFFC20E), Color(0x00FFC20E)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = A2CColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ChartPainter oldDelegate) => false;
}
