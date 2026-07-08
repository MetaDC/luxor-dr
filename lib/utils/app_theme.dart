import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DrColors {
  // ── Brand palette ──────────────────────────────────────────────────────────
  // Primary color: Practo Blue
  static const Color primary = Color(0xFF28328C);

  // Light blue for tinted backgrounds, chip fills, badges
  static const Color primaryLight = Color(0xFFEFF0FA);
  // Deeper dark blue for pressed states, outlined borders, bold text
  static const Color primaryDark = Color(0xFF1B2260);

  // ── Meeting accent ─────────────────────────────────────────────────────────
  // Accent color: Practo Orange
  static const Color accent = Color(0xFFFFA000);
  static const Color accentLight = Color(0xFFFFF7E6);

  // ── Layout ─────────────────────────────────────────────────────────────────
  // Page scaffold: pure white
  static const Color background = Color(0xFFFFFFFF);
  // Card/surface: pure white
  static const Color surface = Color(0xFFFFFFFF);
  // Borders: very light gray (almost white)
  static const Color border = Color(0xFFE4E4E7);
  // Thin dividers: subtle light gray
  static const Color divider = Color(0xFFF4F4F5);

  // ── Text ───────────────────────────────────────────────────────────────────
  // High contrast text colors
  static const Color textPrimary = Color(0xFF18181B);
  static const Color textSecondary = Color(0xFF52525B);
  static const Color textTertiary = Color(0xFF8F8F94);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2D7A4F);
  static const Color successBg = Color(0xFFEDF7F1);
  static const Color warning = Color(0xFFB45309);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFB91C1C);
  static const Color errorBg = Color(0xFFFEE2E2);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: DrColors.background,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: DrColors.primary,
        onPrimary: Colors.white,
        primaryContainer: DrColors.primaryLight,
        onPrimaryContainer: DrColors.primaryDark,
        secondary: DrColors.accent,
        onSecondary: Colors.white,
        secondaryContainer: DrColors.accentLight,
        onSecondaryContainer: DrColors.accent,
        surface: DrColors.surface,
        onSurface: DrColors.textPrimary,
        error: DrColors.error,
        onError: Colors.white,
        outline: DrColors.border,
        outlineVariant: DrColors.divider,
        surfaceContainerHighest: DrColors.primaryLight,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: DrColors.textPrimary,
        displayColor: DrColors.textPrimary,
      ),
      cardTheme: const CardThemeData(
        color: DrColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: DrColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DrColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DrColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DrColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DrColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DrColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DrColors.error, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: DrColors.textTertiary,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: DrColors.textSecondary,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: DrColors.primary,
          fontWeight: FontWeight.w500,
        ),
        errorStyle: GoogleFonts.inter(fontSize: 12, color: DrColors.error),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DrColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: DrColors.border,
          disabledForegroundColor: DrColors.textTertiary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DrColors.primaryDark,
          side: const BorderSide(color: DrColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DrColors.primaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: DrColors.surface,
        selectedColor: DrColors.primaryLight,
        side: const BorderSide(color: DrColors.border),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: DrColors.textSecondary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      dividerTheme: const DividerThemeData(
        color: DrColors.divider,
        space: 1,
        thickness: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: DrColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: DrColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: DrColors.textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: DrColors.surface,
        selectedItemColor: DrColors.primary,
        unselectedItemColor: DrColors.textTertiary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: DrColors.textPrimary,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: DrColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: DrColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return DrColors.primary;
          return DrColors.border;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected))
            return DrColors.primaryLight;
          return DrColors.divider;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return DrColors.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: DrColors.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: DrColors.surface,
        iconColor: DrColors.textSecondary,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: DrColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: DrColors.border),
        ),
        elevation: 4,
        textStyle: GoogleFonts.inter(fontSize: 14, color: DrColors.textPrimary),
      ),
    );
  }
}
