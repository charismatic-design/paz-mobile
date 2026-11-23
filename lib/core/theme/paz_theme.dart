import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PazColors {
  PazColors._();

  // Backgrounds & Surfaces
  static const Color canvas = Color(0xFF080A0D);
  static const Color surface = Color(0xFF0D1117);
  static const Color card = Color(0xFF12151B);
  static const Color cardElevated = Color(0xFF161B22);
  static const Color inputFill = Color(0xFF080A0D);

  // Borders
  static const Color cardBorder = Color(0x14FFFFFF); // rgba(255, 255, 255, 0.08)
  static const Color cardBorderStrong = Color(0x26FFFFFF); // rgba(255, 255, 255, 0.15)
  static const Color inputBorder = Color(0x1FFFFFFF); // rgba(255, 255, 255, 0.12)

  // Accents
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldHover = Color(0xFF059669);
  static const Color emeraldMuted = Color(0x1F10B981); // 12% opacity
  static const Color sky = Color(0xFF38BDF8);
  static const Color skyMuted = Color(0x1F38BDF8);
  static const Color amber = Color(0xFFF59E0B);
  static const Color red = Color(0xFFEF4444);
  static const Color redMuted = Color(0x1FEF4444);

  // Typography
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF64748B);
}

class PazTheme {
  PazTheme._();

  static ThemeData get darkTheme {
    final baseText = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: PazColors.canvas,
      primaryColor: PazColors.emerald,
      colorScheme: const ColorScheme.dark(
        primary: PazColors.emerald,
        onPrimary: PazColors.canvas,
        secondary: PazColors.emeraldHover,
        surface: PazColors.surface,
        onSurface: PazColors.textPrimary,
        error: PazColors.red,
        onError: Colors.white,
      ),
      textTheme: baseText.copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          color: PazColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          color: PazColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.01,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          color: PazColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.01,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          color: PazColors.textSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: GoogleFonts.plusJakartaSans(
          color: PazColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          color: PazColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          color: PazColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          color: PazColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          color: PazColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: GoogleFonts.plusJakartaSans(
          color: PazColors.textDim,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: PazColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: PazColors.textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: PazColors.surface,
        elevation: 8,
        selectedItemColor: PazColors.emerald,
        unselectedItemColor: PazColors.textDim,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PazColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: PazColors.textDim,
          fontSize: 13,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: PazColors.textMuted,
          fontSize: 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: PazColors.inputBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: PazColors.emerald, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: PazColors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: PazColors.red, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PazColors.emerald,
          foregroundColor: PazColors.canvas,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PazColors.textPrimary,
          side: const BorderSide(color: PazColors.cardBorderStrong),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: PazColors.emerald,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: PazColors.cardBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // Monospace numeric styling with Tabular Figures
  static TextStyle monoNumber({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w600,
    Color color = PazColors.textPrimary,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  // Standard PAZ Card Decoration
  static BoxDecoration cardDecoration({
    Color background = PazColors.card,
    Color borderColor = PazColors.cardBorder,
    double borderRadius = 10.0,
    bool glow = false,
  }) {
    return BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: 1),
      boxShadow: glow
          ? [
              BoxShadow(
                color: PazColors.emerald.withValues(alpha: 0.12),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ]
          : null,
    );
  }
}
