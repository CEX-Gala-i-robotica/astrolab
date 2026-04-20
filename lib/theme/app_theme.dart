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
    colors: [Color(0xFF020A12), Color(0xFF041525), Color(0xFF020A12)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00B4D8), Color(0xFF90E0EF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D2137), Color(0xFF071520)],
  );
}

class AppTextStyles {
  static const TextStyle heroTitle = TextStyle(
    fontSize: 52,
    fontWeight: FontWeight.w900,
    color: Color(0xFFFFFFFF),
    height: 1.1,
    letterSpacing: -1.5,
  );

  static const TextStyle heroTitleAccent = TextStyle(
    fontSize: 52,
    fontWeight: FontWeight.w900,
    color: Color(0xFF00B4D8),
    height: 1.1,
    letterSpacing: -1.5,
  );

  static const TextStyle heroSubtitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: Color(0xFFB0C4D8),
    height: 1.6,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: Color(0xFFFFFFFF),
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle sectionSubtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Color(0xFFB0C4D8),
    height: 1.6,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: Color(0xFFFFFFFF),
    height: 1.3,
  );

  static const TextStyle cardBody = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Color(0xFFB0C4D8),
    height: 1.6,
  );

  static const TextStyle navLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Color(0xFFB0C4D8),
    letterSpacing: 0.2,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Color(0xFFFFFFFF),
    letterSpacing: 0.3,
  );

  static const TextStyle stepNumber = TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.w900,
    color: Color(0xFF00B4D8),
    height: 1.0,
  );
}