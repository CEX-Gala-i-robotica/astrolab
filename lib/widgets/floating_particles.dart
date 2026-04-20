import 'dart:math';
import 'package:flutter/material.dart';
import 'package:astrolab/theme/app_theme.dart';

class FloatingParticles extends StatefulWidget {
  const FloatingParticles({super.key});

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with TickerProviderStateMixin {
  late List<_Particle> _particles;
  late AnimationController _controller;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(80, (i) => _Particle.random(_random));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ParticlePainter(
        particles: _particles,
        progress: _controller.value,
      ),
      child: Container(),
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;
  final Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.color,
  });

  factory _Particle.random(Random rnd) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.light,
      Colors.white,
    ];
    return _Particle(
      x: rnd.nextDouble(),
      y: rnd.nextDouble(),
      size: rnd.nextDouble() * 2.5 + 0.5,
      speed: rnd.nextDouble() * 0.3 + 0.05,
      opacity: rnd.nextDouble() * 0.6 + 0.1,
      color: colors[rnd.nextInt(colors.length)],
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(p.opacity)
        ..style = PaintingStyle.fill;

      final dy = (p.y + progress * p.speed) % 1.0;
      final dx = p.x + sin(progress * 2 * pi * p.speed + p.y * 10) * 0.02;

      canvas.drawCircle(
        Offset(dx * size.width, dy * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}