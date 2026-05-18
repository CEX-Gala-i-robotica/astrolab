import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Fundal imersiv global: gradient radial (indigo → obsidian) + stele statice și clipitoare.
class CosmicBackground extends StatefulWidget {
  const CosmicBackground({super.key});

  @override
  State<CosmicBackground> createState() => _CosmicBackgroundState();
}

class _CosmicBackgroundState extends State<CosmicBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _twinkle;
  final _rnd = math.Random(42);
  late final List<_StarDot> _stars;

  @override
  void initState() {
    super.initState();
    _stars = List.generate(260, (_) => _StarDot.random(_rnd));
    _twinkle = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _twinkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.85),
                radius: 1.35,
                colors: [
                  Color(0xFF1e1b4b),
                  Color(0xFF0f0a1a),
                  Color(0xFF020208),
                ],
                stops: [0.0, 0.42, 1.0],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _twinkle,
            builder: (context, _) {
              return CustomPaint(
                painter: _StarfieldPainter(
                  t: _twinkle.value,
                  stars: _stars,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StarDot {
  final double x;
  final double y;
  final double radius;
  final double baseOpacity;
  final double twinklePhase;
  final double twinkleSpeed;
  final bool twinkles;

  _StarDot({
    required this.x,
    required this.y,
    required this.radius,
    required this.baseOpacity,
    required this.twinklePhase,
    required this.twinkleSpeed,
    required this.twinkles,
  });

  factory _StarDot.random(math.Random rnd) {
    final tw = rnd.nextDouble() < 0.42;
    return _StarDot(
      x: rnd.nextDouble(),
      y: rnd.nextDouble(),
      radius: rnd.nextDouble() * 1.35 + 0.25,
      baseOpacity: 0.22 + rnd.nextDouble() * 0.55,
      twinklePhase: rnd.nextDouble() * 2 * math.pi,
      twinkleSpeed: 1.2 + rnd.nextDouble() * 2.8,
      twinkles: tw,
    );
  }

  double opacityAt(double t) {
    if (!twinkles) return baseOpacity;
    final pulse = 0.45 +
        0.55 *
            (0.5 +
                0.5 *
                    math.sin(t * 2 * math.pi * twinkleSpeed + twinklePhase));
    return (baseOpacity * pulse).clamp(0.08, 1.0);
  }
}

class _StarfieldPainter extends CustomPainter {
  final double t;
  final List<_StarDot> stars;

  _StarfieldPainter({required this.t, required this.stars});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final s in stars) {
      final o = s.opacityAt(t);
      paint.color = Color.lerp(
        const Color(0xFFE0E7FF),
        Colors.white,
        (s.radius / 1.6).clamp(0.0, 1.0),
      )!.withValues(alpha: o);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}
