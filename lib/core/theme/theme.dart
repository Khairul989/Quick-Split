import 'package:flutter/material.dart';

/// App theme configuration for QuickSplit
/// Updated using OPTION A — Modern Fintech Blue palette
class QuickSplitTheme {
  QuickSplitTheme._();

  /// ===== COLOR PALETTE =====
  static const Color primary600 = Color(0xFF2563EB);
  static const Color primary500 = Color(0xFF3B82F6);
  static const Color primary400 = Color(0xFF60A5FA);
  static const Color primary300 = Color(0xFF93C5FD);
  static const Color primaryDark = Color(0xFF1E40AF);

  static const Color accentMint = Color(0xFF10B981);

  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color borderLight = Color(0xFFE2E8F0);

  static const Color bgDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color borderDark = Color(0xFF334155);

  /// ============================================================
  /// LIGHT THEME
  /// ============================================================
  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primary600,
      scaffoldBackgroundColor: bgLight,
      fontFamily: 'Inter',

      colorScheme: const ColorScheme.light(
        primary: primary600,
        primaryContainer: primary300,
        secondary: accentMint,
        surface: surfaceLight,
        onPrimary: Colors.white,
        onSurface: textPrimaryLight,
        error: Color(0xFFDC2626),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceLight,
        elevation: 0,
        foregroundColor: textPrimaryLight,
      ),

      dividerColor: borderLight,

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimaryLight),
        bodyMedium: TextStyle(color: textPrimaryLight),
        labelLarge: TextStyle(color: textPrimaryLight),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary600,
          side: const BorderSide(color: primary600),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      /// *** TEXT BUTTON STYLE (ADDED) ***
      textButtonTheme: TextButtonThemeData(
        style:
            TextButton.styleFrom(
              foregroundColor: primary600,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ).copyWith(
              overlayColor: WidgetStateProperty.all(
                primary300.withValues(alpha: 0.2),
              ),
            ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary600, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondaryLight),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      ),

      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderLight),
        ),
      ),
    );
  }

  /// ============================================================
  /// DARK THEME
  /// ============================================================
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryDark,
      scaffoldBackgroundColor: bgDark,
      fontFamily: 'Inter',

      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        primaryContainer: surfaceDark,
        secondary: accentMint,
        surface: surfaceDark,
        onPrimary: Colors.white,
        onSurface: textPrimaryDark,
        error: Color(0xFFDC2626),
      ),

      dividerColor: borderDark,

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimaryDark),
        bodyMedium: TextStyle(color: textPrimaryDark),
        labelLarge: TextStyle(color: textPrimaryDark),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryDark,
          side: const BorderSide(color: primaryDark),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      /// *** TEXT BUTTON STYLE (ADDED) ***
      textButtonTheme: TextButtonThemeData(
        style:
            TextButton.styleFrom(
              foregroundColor: primary400,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ).copyWith(
              overlayColor: WidgetStateProperty.all(
                primaryDark.withValues(alpha: 0.25),
              ),
            ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryDark, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondaryDark),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      ),

      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderDark),
        ),
      ),
    );
  }
}

/// App spacing constants
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

/// App border radius constants
class AppRadius {
  AppRadius._();

  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
}
