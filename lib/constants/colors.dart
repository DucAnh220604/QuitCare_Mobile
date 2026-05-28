import 'package:flutter/material.dart';

class AppColors {
  // Primary colors - BLUE THEME
  static const Color primaryBlue = Color(0xFF0066CC);
  static const Color lightBlue = Color(0xFF6699FF);
  static const Color darkBlue = Color(0xFF003D7A);
  static const Color accentBlue = Color(0xFF0080FF);

  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF8F9FA);
  static const Color mediumGrey = Color(0xFFE9ECEF);
  static const Color darkGrey = Color(0xFF6C757D);
  static const Color black = Color(0xFF191C1D);

  // Status colors
  static const Color success = Color(0xFF28A745);
  static const Color warning = Color(0xFFFFC107);
  static const Color danger = Color(0xFFDC3545);
  static const Color info = Color(0xFF17A2B8);

  // Gradient - BLUE THEME
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, accentBlue],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkBlue, primaryBlue],
  );

  // Material Design 3 - Semantic colors
  static const Color primary = primaryBlue;
  static const Color onPrimary = white;
  static const Color primaryContainer = lightBlue;
  static const Color onPrimaryContainer = darkBlue;

  static const Color secondary = accentBlue;
  static const Color onSecondary = white;
  static const Color secondaryContainer = Color(0xFFE3F2FD);
  static const Color onSecondaryContainer = darkBlue;

  static const Color tertiary = Color(0xFF4CAF50);
  static const Color onTertiary = white;

  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = white;
  static const Color surfaceVariant = lightGrey;
  static const Color onSurface = black;
  static const Color onSurfaceVariant = mediumGrey;

  static const Color outline = Color(0xFFD0D0D0);
  static const Color outlineVariant = Color(0xFFE0E0E0);

  // Text colors
  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF616161);
  static const Color textTertiary = Color(0xFF9E9E9E);

  // Additional semantic colors
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x1F000000);
  static const Color scrim = Color(0xFF000000);
}
