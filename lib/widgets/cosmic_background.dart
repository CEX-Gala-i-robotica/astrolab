import 'dart:math';
import 'package:flutter/material.dart';
import 'package:astrolab/theme/app_theme.dart';

/// Fundal cosmic animat full-screen:
/// - gradient de fond
/// - 3 nebule care pulsează
/// - 200 stele care sclipesc
/// - 5 stele căzătoare
class CosmicBackground extends StatefulWidget {
  const CosmicBackground({super.key});

  @override
  State<CosmicBackground> createState() => _CosmicBackgroundState();
}

class _CosmicBackgroundState extends State<CosmicBackground>
    with TickerProviderStateMixin {
  late final AnimationController _masterCtrl;
  final _rnd = Random(13);
  late final List<_Star> _stars;
  late final List<_ShootingStar> _shooters;

  @override
  void initState() {
    super.initState();
    _stars    = List.generate(220, (_) => _Star.random(_rnd));
    _shooters = List.generate(5,   (_) => _ShootingStar.random(_rnd));

    _masterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _masterCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _masterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _CosmicPainter(
          t: _masterCtrl.value,
          stars: _stars,
          shooters: _shooters,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Star {
  final double x, y, r, phase;
  final Color color;
  _Star({required this.x, required this.y, required this.r,
    required this.phase, required this.color});
  factory _Star.random(Random rnd) {
    const colors = [Colors.white, AppColors.secondary, AppColors.light];
    return _Star(
      x: rnd.nextDouble(),
      y: rnd.nextDouble(),
      r: rnd.nextDouble() * 1.5 + 0.3,
      phase: rnd.nextDouble() * 2 * pi,
      color: colors[rnd.nextInt(colors.length)],
    );
  }
}

class _ShootingStar {
  final double sx, sy, angle, speed, len, delay;
  _ShootingStar({required this.sx, required this.sy, required this.angle,
    required this.speed, required this.len, required this.delay});
  factory _ShootingStar.random(Random rnd) => _ShootingStar(
    sx:    rnd.nextDouble(),
    sy:    rnd.nextDouble() * 0.55,
    angle: pi / 5 + rnd.nextDouble() * pi / 7,
    speed: 0.20 + rnd.nextDouble() * 0.14,
    len:   0.07 + rnd.nextDouble() * 0.06,
    delay: rnd.nextDouble(),
  );
}

class _CosmicPainter extends CustomPainter {
  final double t;
  final List<_Star> stars;
  final List<_ShootingStar> shooters;

  _CosmicPainter({required this.t, required this.stars, required this.shooters});

  @override
  void paint(Canvas canvas, Size size) {
    _bg(canvas, size);
    _nebulae(canvas, size);
    _drawStars(canvas, size);
    _drawShooters(canvas, size);
  }

  void _bg(Canvas canvas, Size size) {
    final p = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF010810), Color(0xFF020A12), Color(0xFF010D18)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, p);
  }

  void _nebulae(Canvas canvas, Size size) {
    final pulse = sin(t * 2 * pi);

    // nebula cyan — top right
    _drawNebula(canvas, size,
        cx: 0.82, cy: 0.12,
        r: size.width * 0.32,
        base: AppColors.primary,
        opacity: 0.065 + pulse * 0.03);

    // nebula blue — mid left
    _drawNebula(canvas, size,
        cx: 0.10, cy: 0.48,
        r: size.width * 0.26,
        base: const Color(0xFF0077B6),
        opacity: 0.055 + pulse * 0.025);

    // nebula teal — bottom center
    _drawNebula(canvas, size,
        cx: 0.52, cy: 0.88,
        r: size.width * 0.28,
        base: AppColors.secondary,
        opacity: 0.045 + pulse * 0.02);

    // nebula deep — top left
    _drawNebula(canvas, size,
        cx: 0.18, cy: 0.14,
        r: size.width * 0.20,
        base: const Color(0xFF023E58),
        opacity: 0.04 + pulse * 0.015);
  }

  void _drawNebula(Canvas canvas, Size size,
      {required double cx, required double cy,
        required double r, required Color base, required double opacity}) {
    final center = Offset(cx * size.width, cy * size.height);
    final p = Paint()
      ..shader = RadialGradient(colors: [
        base.withOpacity(opacity),
        base.withOpacity(opacity * 0.4),
        Colors.transparent,
      ], stops: const [0.0, 0.5, 1.0]).createShader(
          Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, p);
  }

  void _drawStars(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    for (final s in stars) {
      final twinkle = 0.3 + 0.7 * (0.5 + 0.5 * sin(t * 2 * pi * 2 + s.phase));
      p.color = s.color.withOpacity(twinkle * 0.75);
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.r, p);
    }
  }

  void _drawShooters(Canvas canvas, Size size) {
    for (final s in shooters) {
      final raw = (t + s.delay) % 1.0;
      // active window: 0..0.55 of the cycle
      if (raw > 0.55) continue;
      final prog = raw / 0.55;

      final hx = (s.sx + cos(s.angle) * s.speed * prog) * size.width;
      final hy = (s.sy + sin(s.angle) * s.speed * prog) * size.height;
      final tailFactor = min(prog * 2, 1.0);
      final tx = hx - cos(s.angle) * s.len * size.width  * tailFactor;
      final ty = hy - sin(s.angle) * s.len * size.height * tailFactor;

      final fade = prog < 0.15 ? prog / 0.15 : prog > 0.82 ? (1 - prog) / 0.18 : 1.0;

      final paint = Paint()
        ..shader = LinearGradient(colors: [
          Colors.white.withOpacity(0.92 * fade),
          AppColors.secondary.withOpacity(0.35 * fade),
          Colors.transparent,
        ]).createShader(Rect.fromPoints(Offset(hx, hy), Offset(tx, ty)))
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(hx, hy), Offset(tx, ty), paint);

      // cap glow
      canvas.drawCircle(
        Offset(hx, hy),
        1.8,
        Paint()
          ..color = Colors.white.withOpacity(0.8 * fade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicPainter old) => old.t != t;
}