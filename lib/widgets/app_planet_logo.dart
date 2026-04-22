import 'package:flutter/material.dart';

/// AstroLab planet logo — folosește imaginea din assets dacă există,
/// altfel desenează o planetă vectorială identică cu cea din hero.
class AppPlanetLogo extends StatelessWidget {
  final double size;

  const AppPlanetLogo({super.key, required this.size});

  static const String assetPath = 'assets/images/astrolab_planet.png';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _VectorPlanet(size: size),
      ),
    );
  }
}

/// Planetă vectorială fallback — identică vizual cu cea animată din hero
class _VectorPlanet extends StatelessWidget {
  final double size;
  const _VectorPlanet({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.35, -0.35),
          radius: 1.0,
          colors: [
            Color(0xFF52D4F0),
            Color(0xFF00B4D8),
            Color(0xFF006E8A),
            Color(0xFF013850),
            Color(0xFF010F1A),
          ],
          stops: [0.0, 0.25, 0.55, 0.8, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF00B4D8),
            blurRadius: size * 0.3,
            spreadRadius: size * 0.02,
          ),
        ],
      ),
      child: ClipOval(
        child: CustomPaint(painter: _PlanetSwirlPainter()),
      ),
    );
  }
}

class _PlanetSwirlPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.018
      ..color = Colors.white.withOpacity(0.12);

    for (int i = 0; i < 4; i++) {
      final y = size.height * (0.28 + i * 0.15);
      final rect = Rect.fromCenter(
        center: Offset(size.width * 0.5, y),
        width: size.width * (0.7 + i * 0.08),
        height: size.height * 0.12,
      );
      canvas.drawArc(rect, 0, 3.14159, false, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}