import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // Apple typography styling helper
  static TextTheme _buildTextTheme(Color textColor) {
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(color: textColor, letterSpacing: -1.0, height: 1.1),
      displayMedium: GoogleFonts.inter(color: textColor, letterSpacing: -0.8, height: 1.15),
      displaySmall: GoogleFonts.inter(color: textColor, letterSpacing: -0.5, height: 1.2),
      headlineLarge: GoogleFonts.inter(color: textColor, letterSpacing: -0.3, height: 1.2),
      headlineMedium: GoogleFonts.inter(color: textColor, letterSpacing: -0.2, height: 1.25),
      headlineSmall: GoogleFonts.inter(color: textColor, letterSpacing: -0.1, height: 1.3),
      titleLarge: GoogleFonts.inter(color: textColor, letterSpacing: -0.1, height: 1.3, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.inter(color: textColor, letterSpacing: 0, height: 1.4),
      titleSmall: GoogleFonts.inter(color: textColor, letterSpacing: 0.1, height: 1.4),
      bodyLarge: GoogleFonts.inter(color: textColor, letterSpacing: 0, height: 1.5),
      bodyMedium: GoogleFonts.inter(color: textColor, letterSpacing: 0.1, height: 1.5),
      bodySmall: GoogleFonts.inter(color: textColor, letterSpacing: 0.2, height: 1.5),
      labelLarge: GoogleFonts.inter(color: textColor, letterSpacing: 0.1),
      labelMedium: GoogleFonts.inter(color: textColor, letterSpacing: 0.2),
      labelSmall: GoogleFonts.inter(color: textColor, letterSpacing: 0.3),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.primaryDark,
        surface: AppColors.background,
        brightness: Brightness.light,
      ),
      textTheme: _buildTextTheme(AppColors.textPrimary),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // Translucent for Apple design
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.backgroundDark,
        brightness: Brightness.dark,
      ),
      textTheme: _buildTextTheme(AppColors.textPrimaryDark),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // Translucent for Apple design
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
