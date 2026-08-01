import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Design System — Deep Violet
  static const Color primary = Color(0xFF5D3FD3);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color textDark = Color(0xFF191C1D);
  static const Color textMuted = Color(0xFF8A8C8E);
  static const Color border = Color(0xFFE8E8F0);
  static const Color primaryContainer = Color(0xFFEDE8FC);

  /// Görev satırı başlığı — Dashboard _TaskRow ve Timeline _TaskCard ortak stili.
  /// Renk ve üstü-çizili efekt çağrı tarafında uygulanır (task.isCompleted'a göre).
  static TextStyle taskTitleStyle({
    required bool completed,
  }) =>
      GoogleFonts.syne(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: completed ? textMuted : textDark,
        decoration: completed ? TextDecoration.lineThrough : null,
        decorationColor: textMuted,
      );

  static ThemeData get theme {
    final base = ColorScheme.fromSeed(seedColor: primary).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: primary,
      surface: surface,
      onSurface: textDark,
      onSurfaceVariant: textMuted,
      outline: border,
      outlineVariant: const Color(0xFFEEEEF8),
      error: const Color(0xFFB00020),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.dmSansTextTheme().copyWith(
        displayLarge: GoogleFonts.syne(
            color: textDark, fontWeight: FontWeight.w800),
        displayMedium: GoogleFonts.syne(
            color: textDark, fontWeight: FontWeight.w800),
        displaySmall: GoogleFonts.syne(
            color: textDark, fontWeight: FontWeight.w700),
        headlineLarge: GoogleFonts.syne(
            color: textDark, fontWeight: FontWeight.w700),
        headlineMedium: GoogleFonts.syne(
            color: textDark, fontWeight: FontWeight.w700),
        headlineSmall: GoogleFonts.syne(
            color: textDark, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.syne(
            color: textDark, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        titleTextStyle: GoogleFonts.syne(
          color: textDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.50),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        labelStyle: GoogleFonts.dmSans(color: textMuted, fontSize: 14),
        floatingLabelStyle: GoogleFonts.dmSans(color: primary, fontSize: 12),
        hintStyle: GoogleFonts.dmSans(
            color: textMuted.withValues(alpha: 0.55)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFB00020)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFB00020), width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withValues(alpha: 0.40),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: primary),
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}
