import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// APP COLORS  –  White-background luxury gold theme
// (matches _P palette from data_tab.dart)
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  // Backgrounds
  static const Color bg         = Color(0xFFFAF9F6); // warm off-white
  static const Color card       = Color(0xFFFFFFFF); // pure white card
  static const Color cardBorder = Color(0xFFEDE9E1); // warm cream border
  static const Color surface    = Color(0xFFF4F1EB); // slightly tinted surface

  //orange
  static const Color lightOrange    = Color(0xFFFFD580);


  // Gold
  static const Color gold      = Color(0xFFB8912A); // deep gold (primary)
  static const Color goldLight = Color(0xFFD4A853); // standard gold
  static const Color goldDim   = Color(0xFF8C6B2F); // dark gold
  static const Color goldBg    = Color(0xFFFDF6E7); // very light gold tint

  // Text
  static const Color textBlack   = Color(0xFF000000);
  static const Color textPrimary   = Color(0xFF1A1610);
  static const Color textSecondary = Color(0xFF7A7060);
  static const Color textMuted     = Color(0xFFB0A898);
  static const Color textHint      = Color(0xFFB0A898);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color error   = Color(0xFFC0392B);
  static const Color warning = Color(0xFFE67E22);
  static const Color info    = Color(0xFF2980B9);

  // ── Backward-compat aliases ────────────────────────────────────────────
  // Old brand names kept so existing screens automatically pick up the new
  // white-gold theme without needing edits.
  static const Color primaryNavy  = gold;       // primary colour now gold
  static const Color primaryRed   = error;
  static const Color accentYellow = goldLight;
  static const Color accentGreen  = gold;       // accents are gold now
  static const Color creamBg      = bg;
  static const Color softCream    = goldBg;
  static const Color cardBg       = card;
  static const Color divider      = cardBorder;

  // Gradients
  static const List<Color> gradientButton = [goldLight, goldDim];
  static const List<Color> gradientAppBar = [goldLight, goldDim];
  static const List<Color> gradientGold   = [goldLight, goldDim];
}

// ─────────────────────────────────────────────────────────────────────────────
// APP THEME
// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: AppColors.gold,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.gold,
        primary: AppColors.gold,
        secondary: AppColors.goldLight,
        background: AppColors.bg,
        surface: AppColors.card,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.dmSansTextTheme().apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.cormorantGaramond(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        systemOverlayStyle: null,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: GoogleFonts.dmSans(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.dmSans(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gold,
          side: const BorderSide(color: AppColors.goldLight, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold,
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.cardBorder,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.gold,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.white,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.goldBg,
        labelStyle: GoogleFonts.dmSans(
          color: AppColors.gold,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        side: BorderSide(color: AppColors.goldLight.withOpacity(0.4)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // ── Typography helpers (match data_tab.dart) ──────────────────────────
  static TextStyle headline({
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.textPrimary,
    double height = 1.15,
  }) =>
      GoogleFonts.cormorantGaramond(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
      );

  static TextStyle body({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.textSecondary,
    double height = 1.5,
    double? letterSpacing,
  }) =>
      GoogleFonts.dmSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle eyebrow({
    double fontSize = 10,
    Color color = AppColors.gold,
    double letterSpacing = 3,
  }) =>
      GoogleFonts.dmSans(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: letterSpacing,
      );

  // ── Decoration helpers ────────────────────────────────────────────────

  /// Gold gradient button (matches Premium CTA / dialog button).
  static BoxDecoration gradientButtonDecoration({double radius = 14}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.goldLight, AppColors.goldDim],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: AppColors.gold.withOpacity(0.30),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  /// Horizontal gold gradient (for app bars / banners).
  static BoxDecoration gradientAppBarDecoration() {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.goldLight, AppColors.goldDim],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
    );
  }

  /// White card with cream border and soft shadow (matches grid/premium tiles).
  static BoxDecoration cardDecoration({
    bool highlighted = false,
    double radius = 16,
  }) {
    return BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: highlighted
            ? AppColors.goldLight.withOpacity(0.6)
            : AppColors.cardBorder,
        width: highlighted ? 1.2 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: highlighted
              ? AppColors.gold.withOpacity(0.14)
              : Colors.black.withOpacity(0.04),
          blurRadius: highlighted ? 22 : 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Small gold pill (matches PREMIUM badge).
  static BoxDecoration goldBadgeDecoration({double radius = 6}) {
    return BoxDecoration(
      color: AppColors.goldBg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: AppColors.goldLight.withOpacity(0.4),
        width: 1,
      ),
    );
  }

  /// Circular icon button (matches arrow chip in premium tile).
  static BoxDecoration goldIconCircleDecoration() {
    return BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.goldBg,
      border: Border.all(
        color: AppColors.goldLight.withOpacity(0.4),
        width: 1,
      ),
    );
  }
}