import 'package:flutter/material.dart';

class AppColors {
  // Brand colors
  static const Color primary = Color(0xFF226EAC);       // Lapis blue
  static const Color primaryDark = Color(0xFF185282);
  static const Color primaryLight = Color(0xFFE6F0FA);
  
  // Status colors (Adjusted slightly for dark mode contrast if needed, but these are decent)
  static const Color present = Color(0xFF259538);       // Green
  static const Color absent = Color(0xFFDC2C2C);        // Red
  static const Color holiday = Color(0xFFFFA500);       // Orange
  static const Color cardDefault = Colors.white;
  static const Color cardDark = Color(0xFF1E1E1E);

  // Backgrounds & Neutrals (Light)
  static const Color background = Color(0xFFFBFBFB);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  
  // Backgrounds & Neutrals (Dark)
  static const Color backgroundDark = Color(0xFF121212);
  static const Color cardBorderDark = Color(0xFF333333);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // Accent
  static const Color deleteRed = Color(0xFFEF4444);
  static const Color shadow = Color(0x1A000000);
}
