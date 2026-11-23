import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PazColors {
  PazColors._();

  // Backgrounds & Surfaces (1:1 with paz-web CSS tokens)
  static const Color canvas = Color(0xFF0A0A0A); // --bg-app: deep obsidian base canvas
  static const Color surface = Color(0xFF111111); // --bg-surface: navigation & elevated bar
  static const Color card = Color(0xFF141414); // --bg-card: primary card & data panel
  static const Color cardHover = Color(0xFF181818); // --bg-card-hover: hover / active card
  static const Color cardElevated = Color(0xFF181818); // nested elevation surface
  static const Color inputFill = Color(0xFF0C0C0C); // --bg-inset: control & input surface
  static const Color highlight = Color(0x08FFFFFF); // --bg-highlight: rgba(255, 255, 255, 0.03)

  // Razor-sharp 1px Borders
  static const Color borderSubtle = Color(0xFF222222); // --border-subtle
  static const Color cardBorder = Color(0xFF282828); // --border-card
  static const Color cardBorderStrong = Color(0xFF333333); // --border-strong
  static const Color inputBorder = Color(0xFF282828); // --border-subtle
  static const Color borderFocus = Color(0xFF10B981); // --border-focus

  // Brand Gold
  static const Color gold = Color(0xFFD4AF37); // --gold
  static const Color goldMuted = Color(0xFFB3922D); // --gold-muted
  static const Color goldSubtle = Color(0x1AD4AF37); // rgba(212, 175, 55, 0.10)
  static const Color goldHover = Color(0xFFE5C158); // --gold-hover

  // Semantic Financial Accents
  static const Color emerald = Color(0xFF10B981); // --green
  static const Color emeraldHover = Color(0xFF059669);
  static const Color emeraldMuted = Color(0x1A10B981); // rgba(16, 185, 129, 0.10)
  static const Color emeraldBorder = Color(0x4010B981); // rgba(16, 185, 129, 0.25)

  static const Color red = Color(0xFFF43F5E); // --red (rose)
  static const Color redMuted = Color(0x1AF43F5E); // rgba(244, 63, 94, 0.10)
  static const Color redBorder = Color(0x40F43F5E); // rgba(244, 63, 94, 0.25)

  static const Color sky = Color(0xFF38BDF8);
  static const Color skyMuted = Color(0x1A38BDF8);
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberMuted = Color(0x1AF59E0B);

  // High-contrast Typography Hierarchy (All WCAG AAA/AA compliant)
  static const Color textPrimary = Color(0xFFFAFAFA); // --text-primary
  static const Color textSecondary = Color(0xFFD4D4D4); // --text-secondary
  static const Color textMuted = Color(0xFFA3A3A3); // --text-muted
  static const Color textDim = Color(0xFF94A3B8); // --text-dim
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
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: PazColors.inputBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: PazColors.borderFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: PazColors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
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
            borderRadius: BorderRadius.circular(6),
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
            borderRadius: BorderRadius.circular(6),
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
        color: PazColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // Monospace numeric styling with Tabular Figures (JetBrains Mono)
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

  // Standard PAZ Card Decoration (strictly uniform border)
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
                color: PazColors.emerald.withValues(alpha: 0.10),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ]
          : null,
    );
  }
}
