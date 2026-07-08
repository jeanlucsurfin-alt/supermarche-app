import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Identité visuelle de Fafoutt Store.
///
/// Palette inspirée du marché haïtien : marine profond + or comme piliers,
/// une terre cuite chaude en accent, des verts/rouges volontairement moins
/// "Material par défaut" pour un rendu plus travaillé et moins générique.
class AppColors {
  static const Color navy = Color(0xFF14264A);
  static const Color navyLight = Color(0xFF1E3A64);
  static const Color blue = Color(0xFF3B6485); // bleu ardoise, moins "stock"
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldDark = Color(0xFFA6821F);
  static const Color clay = Color(0xFFBD5B3A); // terre cuite — accent signature
  static const Color clayLight = Color(0xFFE9DDD3);
  static const Color background = Color(0xFFF8F6F1); // ivoire chaud
  static const Color surface = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF2E6B4F); // vert forêt, pas Material
  static const Color danger = Color(0xFFAE3B26); // brique, cousin de clay
  static const Color textPrimary = Color(0xFF14264A);
  static const Color textSecondary = Color(0xFF75695B); // gris chaud
}

/// Rayons d'arrondi différenciés selon le type d'élément, pour éviter le
/// rendu "12px partout" typique des interfaces générées automatiquement.
class AppRadius {
  static const double card = 18;
  static const double button = 10;
  static const double input = 10;
  static const double chip = 22;
  static const double sheet = 24;
}

class AppTheme {
  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.navy,
        primary: AppColors.navy,
        secondary: AppColors.clay,
        tertiary: AppColors.gold,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    // Paire typographique volontairement distinctive : Space Grotesk pour
    // les titres, montants et boutons (caractère, très lisible en chiffres),
    // Work Sans pour le corps de texte (sobre, chaleureux, lisible en petite
    // taille sur mobile).
    final displayFont = GoogleFonts.spaceGrotesk;
    final bodyFont = GoogleFonts.workSans;

    return base.copyWith(
      textTheme: GoogleFonts.workSansTextTheme(base.textTheme).copyWith(
        displayLarge: displayFont(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineMedium: displayFont(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: displayFont(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
        ),
        titleMedium: displayFont(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: bodyFont(color: AppColors.textPrimary, height: 1.4),
        bodyMedium: bodyFont(color: AppColors.textPrimary, height: 1.4),
        bodySmall: bodyFont(color: AppColors.textSecondary, height: 1.35),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: displayFont(
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFD9D2C7),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: displayFont(
            fontWeight: FontWeight.w600,
            fontSize: 14.5,
            letterSpacing: 0.4,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: displayFont(
            fontWeight: FontWeight.w600,
            fontSize: 14.5,
            letterSpacing: 0.4,
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 1.5,
        shadowColor: AppColors.navy.withOpacity(0.10),
        surfaceTintColor: Colors.transparent,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: bodyFont(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: Color(0xFFE6DFD5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: Color(0xFFE6DFD5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.clay, width: 1.6),
        ),
      ),
    );
  }
}
