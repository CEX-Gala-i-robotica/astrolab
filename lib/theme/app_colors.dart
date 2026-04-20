import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF00B4D8);
  static const Color secondary = Color(0xFF90E0EF);
  static const Color light = Color(0xFFCAF0F8);
  static const Color background = Color(0xFF020A12);
  static const Color surface = Color(0xFF071520);
  static const Color surfaceLight = Color(0xFF0D2137);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0C4D8);
  static const Color textMuted = Color(0xFF5A7A90);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF020A12),
      Color(0xFF041525),
      Color(0xFF020A12),
    ],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00B4D8), Color(0xFF90E0EF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0D2137),
      Color(0xFF071520),
    ],
  );
}