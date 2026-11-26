/// App theme — Material 3 ColorScheme light/dark built from the design tokens
/// of the UI/UX Specification §2 (industrial slate + KIANEX orange).
library;

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color orange = Color(0xFFF07E1A);
  static const Color orangeDeep = Color(0xFFE8720A);
  static const Color slate900 = Color(0xFF20262D);
  static const Color slate800 = Color(0xFF2A323B);

  static const String fontFamily = 'Vazirmatn';

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: orange,
      brightness: Brightness.light,
      primary: orangeDeep,
      surface: Colors.white,
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: const Color(0xFFEEF0F3),
      appBarTheme: const AppBarTheme(
        backgroundColor: slate900,
        foregroundColor: Color(0xFFF2F5F8),
        elevation: 0,
        centerTitle: false,
      ),
      cardColor: Colors.white,
      dividerColor: const Color(0xFFE1E5EA),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: orange,
      brightness: Brightness.dark,
      primary: orange,
      surface: const Color(0xFF1C232B),
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: const Color(0xFF12161B),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF171C22),
        foregroundColor: Color(0xFFE8EDF2),
        elevation: 0,
        centerTitle: false,
      ),
      cardColor: const Color(0xFF1C232B),
      dividerColor: const Color(0xFF2B3540),
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDark ? const Color(0xFF2B3540) : const Color(0xFFE1E5EA)),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          side: BorderSide(color: isDark ? const Color(0xFF3E4A57) : const Color(0xFFC9CFD6)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFC9CFD6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: orange, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide.none,
        backgroundColor: isDark ? const Color(0xFF263039) : const Color(0xFFECF0F4),
        labelStyle: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFF97A3AE) : const Color(0xFF38414C),
        ),
      ),
    );
  }
}
