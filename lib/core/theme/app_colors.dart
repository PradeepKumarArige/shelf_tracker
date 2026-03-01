import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Sky Blue
  static const Color primary = Color(0xFF03A9F4);
  static const Color primaryLight = Color(0xFF4FC3F7);
  static const Color primaryDark = Color(0xFF0288D1);
  static const Color primarySurface = Color(0xFFE1F5FE);

  // Category Colors - Light Mode
  static const Color foodLight = Color(0xFF4CAF50);
  static const Color groceryLight = Color(0xFFFF9800);
  static const Color medicineLight = Color(0xFFF44336);
  static const Color cosmeticsLight = Color(0xFF9C27B0);

  // Category Colors - Dark Mode
  static const Color foodDark = Color(0xFF66BB6A);
  static const Color groceryDark = Color(0xFFFFB74D);
  static const Color medicineDark = Color(0xFFEF5350);
  static const Color cosmeticsDark = Color(0xFFBA68C8);

  // Status Colors - Light Mode
  static const Color freshLight = Color(0xFF03A9F4);
  static const Color warningLight = Color(0xFFFF9800);
  static const Color expiredLight = Color(0xFFF44336);
  static const Color usedLight = Color(0xFF9E9E9E);

  // Status Colors - Dark Mode
  static const Color freshDark = Color(0xFF29B6F6);
  static const Color warningDark = Color(0xFFFFB74D);
  static const Color expiredDark = Color(0xFFEF5350);
  static const Color usedDark = Color(0xFFBDBDBD);

  // Light Theme
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1A1A2E);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textTertiaryLight = Color(0xFF9CA3AF);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color dividerLight = Color(0xFFF3F4F6);

  // Dark Theme
  static const Color backgroundDark = Color(0xFF0F1419);
  static const Color surfaceDark = Color(0xFF1C2128);
  static const Color cardDark = Color(0xFF242C38);
  static const Color textPrimaryDark = Color(0xFFE7E9EA);
  static const Color textSecondaryDark = Color(0xFF8B98A5);
  static const Color textTertiaryDark = Color(0xFF6E7681);
  static const Color borderDark = Color(0xFF30363D);
  static const Color dividerDark = Color(0xFF21262D);

  // Navigation
  static const Color navBackgroundLight = Color(0xFFFFFFFF);
  static const Color navBackgroundDark = Color(0xFF1C2128);

  // Shadows
  static Color shadowLight = Colors.black.withOpacity(0.08);
  static Color shadowDark = Colors.black.withOpacity(0.3);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF03A9F4), Color(0xFF0288D1)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF03A9F4), Color(0xFF0277BD)],
  );

  static const LinearGradient splashGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0288D1), Color(0xFF01579B)],
  );
}
