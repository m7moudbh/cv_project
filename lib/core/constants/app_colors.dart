import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette - Deep Navy & Gold
  static const Color primary = Color(0xFF0A0E1A);
  static const Color primaryDark = Color(0xFF050810);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceLight = Color(0xFF1C2537);
  static const Color cardBg = Color(0xFF162032);

  // Accent Colors
  static const Color gold = Color(0xFFFFB800);
  static const Color goldLight = Color(0xFFFFD454);
  static const Color goldDark = Color(0xFFCC9200);
  static const Color accentBlue = Color(0xFF4F8EF7);
  static const Color accentGreen = Color(0xFF00D68F);
  static const Color accentPurple = Color(0xFF9B6DFF);

  // Text Colors
  static const Color textPrimary = Color(0xFFF0F4FF);
  static const Color textSecondary = Color(0xFF8B9ABB);
  static const Color textMuted = Color(0xFF4A5568);
  static const Color textOnGold = Color(0xFF0A0E1A);

  // Borders & Dividers
  static const Color border = Color(0xFF1E2D45);
  static const Color borderLight = Color(0xFF2A3D55);

  // Status Colors
  static const Color error = Color(0xFFFF4F6A);
  static const Color success = Color(0xFF00D68F);
  static const Color warning = Color(0xFFFFB800);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0A0E1A), Color(0xFF111827)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFB800), Color(0xFFFF8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF162032), Color(0xFF1C2537)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient profileGradient = LinearGradient(
    colors: [Color(0xFF0A0E1A), Color(0xFF162032), Color(0xFF1C2537)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Glow Effects
  static List<BoxShadow> goldGlow = [
    BoxShadow(
      color: gold.withOpacity(0.3),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}