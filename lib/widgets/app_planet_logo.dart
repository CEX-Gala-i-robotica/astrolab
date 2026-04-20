import 'package:flutter/material.dart';

/// AstroLab planet artwork (square PNG on dark background).
class AppPlanetLogo extends StatelessWidget {
  final double size;
  final BoxFit fit;

  const AppPlanetLogo({
    super.key,
    required this.size,
    this.fit = BoxFit.contain,
  });

  static const String assetPath = 'assets/images/astrolab_planet.png';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        assetPath,
        fit: fit,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.public_rounded,
          size: size * 0.55,
          color: const Color(0xFF00B4D8),
        ),
      ),
    );
  }
}
