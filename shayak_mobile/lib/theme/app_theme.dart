import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ============================================================================
/// SHAYAK-AI: Accessible Elderly Design System & Theme
/// Conforms to WCAG AAA contrast standards (minimum 7:1 ratio for regular text,
/// 4.5:1 for large text). Optimized specifically for individuals with cognitive
/// decline, cataracts/visual impairment, and Parkinsonian motor tremors.
/// ============================================================================
class AppTheme {
  // Primary Palette Tokens (High Contrast WCAG AAA)
  static const Color darkNavy = Color(0xFF0B192C);      // Deep canvas background
  static const Color cardNavy = Color(0xFF1E3E62);      // Elevated surface containers
  static const Color cardNavyBorder = Color(0xFF4A709C);// High-visibility container outline
  static const Color softWarmCream = Color(0xFFFBF8EF); // High-contrast primary text & surface
  static const Color warmAmber = Color(0xFFF5A623);     // Primary accent / Action callout
  static const Color vibrantCyan = Color(0xFF00E5FF);   // Secondary informational accent
  static const Color alertCoral = Color(0xFFE63946);    // High-visibility critical indicator
  static const Color successMint = Color(0xFF2EC4B6);   // Confirmation / Completion indicator
  static const Color mutedSlate = Color(0xFFB0BEC5);    // High-contrast secondary text (> 4.5:1 on dark)
  static const Color canvasBorder = Color(0xFFD4AF37);  // Clock canvas boundary gold

  // Accessibility Touch Metrics
  static const double minTouchTarget = 56.0;   // WCAG standard minimum tap target
  static const double buttonHeight = 64.0;     // Large accessible buttons for tremor tolerance
  static const double cardBorderRadius = 18.0; // High visual demarcation roundedness
  static const double iconSizeLarge = 36.0;    // Prominent iconography
  static const double iconSizeHero = 48.0;

  /// High-Contrast Dark Theme Specification
  static ThemeData get highContrastTheme {
    final baseTypography = GoogleFonts.outfitTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkNavy,
      primaryColor: warmAmber,
      canvasColor: darkNavy,
      cardColor: cardNavy,

      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: warmAmber,
        onPrimary: darkNavy,
        secondary: softWarmCream,
        onSecondary: darkNavy,
        surface: cardNavy,
        onSurface: softWarmCream,
        error: alertCoral,
        onError: softWarmCream,
      ),

      // WCAG AAA Scaled Typography (Min 18pt body, 28pt+ headings)
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 34.0,
          fontWeight: FontWeight.w800,
          color: softWarmCream,
          letterSpacing: 0.2,
          height: 1.25,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 28.0,
          fontWeight: FontWeight.w700,
          color: softWarmCream,
          letterSpacing: 0.1,
          height: 1.3,
        ),
        headlineLarge: GoogleFonts.outfit(
          fontSize: 26.0,
          fontWeight: FontWeight.w700,
          color: softWarmCream,
          height: 1.3,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 22.0,
          fontWeight: FontWeight.w600,
          color: softWarmCream,
          height: 1.35,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20.0,
          fontWeight: FontWeight.w700,
          color: softWarmCream,
          height: 1.35,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 18.0,
          fontWeight: FontWeight.w600,
          color: warmAmber,
          height: 1.35,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 18.0,
          fontWeight: FontWeight.w500,
          color: softWarmCream,
          letterSpacing: 0.15,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 18.0,
          fontWeight: FontWeight.w400,
          color: mutedSlate,
          letterSpacing: 0.15,
          height: 1.45,
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 18.0,
          fontWeight: FontWeight.w700,
          color: darkNavy,
          letterSpacing: 0.3,
        ),
      ),

      // Accessible Card Theme with 2px high-contrast borders
      cardTheme: CardTheme(
        color: cardNavy,
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardBorderRadius),
          side: const BorderSide(color: cardNavyBorder, width: 2.0),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      ),

      // Ultra-Accessible Large Target Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: warmAmber,
          foregroundColor: darkNavy,
          minimumSize: const Size(minTouchTarget, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          elevation: 6.0,
          shadowColor: Colors.black54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: const BorderSide(color: softWarmCream, width: 2.0),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 20.0,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // Outlined Buttons with clear high-contrast borders
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: softWarmCream,
          minimumSize: const Size(minTouchTarget, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          side: const BorderSide(color: softWarmCream, width: 2.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Bottom Navigation Theme (large icons with guaranteed persistent text labels)
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkNavy,
        selectedItemColor: warmAmber,
        unselectedItemColor: mutedSlate,
        selectedLabelStyle: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 15.0,
          fontWeight: FontWeight.w600,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 12.0,
      ),

      // Dialogs with thick border indicators
      dialogTheme: DialogTheme(
        backgroundColor: darkNavy,
        elevation: 16.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: const BorderSide(color: softWarmCream, width: 2.5),
        ),
      ),
    );
  }
}
