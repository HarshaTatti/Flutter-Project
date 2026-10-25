import 'package:flutter/material.dart';

/// Available themes for the Privacy-Preserving Chatbot application
enum AppTheme {
  light,
  dark,
  highContrast,
}

extension AppThemeExtension on AppTheme {
  String get displayName {
    switch (this) {
      case AppTheme.light:
        return 'Light';
      case AppTheme.dark:
        return 'Dark';
      case AppTheme.highContrast:
        return 'High Contrast';
    }
  }

  String get description {
    switch (this) {
      case AppTheme.light:
        return 'Clean light appearance with balanced indigo and slate tones.';
      case AppTheme.dark:
        return 'Modern dark appearance with deep slate background and vibrant accents.';
      case AppTheme.highContrast:
        return 'Maximum accessibility: pure black background, bright yellow/cyan highlights, and crisp borders.';
    }
  }

  IconData get icon {
    switch (this) {
      case AppTheme.light:
        return Icons.light_mode_rounded;
      case AppTheme.dark:
        return Icons.dark_mode_rounded;
      case AppTheme.highContrast:
        return Icons.contrast_rounded;
    }
  }

  String get key {
    switch (this) {
      case AppTheme.light:
        return 'light';
      case AppTheme.dark:
        return 'dark';
      case AppTheme.highContrast:
        return 'high_contrast';
    }
  }

  static AppTheme fromKey(String? key) {
    switch (key) {
      case 'dark':
        return AppTheme.dark;
      case 'high_contrast':
        return AppTheme.highContrast;
      case 'light':
      default:
        return AppTheme.light;
    }
  }
}

/// Centralized ThemeData definitions for Light, Dark, and High-Contrast themes
class AppThemes {
  AppThemes._();

  /// 1. Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Slate 50
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF4F46E5), // Indigo 600
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFEEF2FF), // Indigo 50
      onPrimaryContainer: Color(0xFF312E81), // Indigo 900
      secondary: Color(0xFF7C3AED), // Violet 600
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFF5F3FF),
      onSecondaryContainer: Color(0xFF4C1D95),
      tertiary: Color(0xFF0EA5E9), // Sky 500
      onTertiary: Colors.white,
      error: Color(0xFFDC2626), // Red 600
      onError: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF0F172A), // Slate 900
      surfaceContainerHighest: Color(0xFFF1F5F9), // Slate 100
      outline: Color(0xFFCBD5E1), // Slate 300
      outlineVariant: Color(0xFFE2E8F0), // Slate 200
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF0F172A),
      iconTheme: IconThemeData(color: Color(0xFF0F172A)),
      titleTextStyle: TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF4F46E5),
        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF4F46E5),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 14,
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      titleTextStyle: TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: TextStyle(
        color: Color(0xFF334155),
        fontSize: 14,
        height: 1.5,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE2E8F0),
      thickness: 1,
      space: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF1F5F9),
      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      labelStyle: const TextStyle(
        color: Color(0xFF334155),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
    ),
  );

  /// 2. Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0B0F19), // Deep slate black
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF6366F1), // Indigo 500
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF312E81), // Indigo 900
      onPrimaryContainer: Color(0xFFE0E7FF), // Indigo 100
      secondary: Color(0xFF8B5CF6), // Violet 500
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF4C1D95),
      onSecondaryContainer: Color(0xFFEDE9FE),
      tertiary: Color(0xFF38BDF8), // Sky 400
      onTertiary: Color(0xFF082F49),
      error: Color(0xFFEF4444), // Red 500
      onError: Colors.white,
      surface: Color(0xFF1E293B), // Slate 800
      onSurface: Color(0xFFF8FAFC), // Slate 50
      surfaceContainerHighest: Color(0xFF0F172A), // Slate 900
      outline: Color(0xFF334155), // Slate 700
      outlineVariant: Color(0xFF1E293B), // Slate 800
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      backgroundColor: Color(0xFF0B0F19),
      foregroundColor: Color(0xFFF8FAFC),
      iconTheme: IconThemeData(color: Color(0xFFF8FAFC)),
      titleTextStyle: TextStyle(
        color: Color(0xFFF8FAFC),
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E293B),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF334155), width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF818CF8),
        side: const BorderSide(color: Color(0xFF475569), width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF818CF8),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF0F172A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF334155), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF334155), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF818CF8), width: 2),
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 14,
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Color(0xFF1E293B),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: Color(0xFF334155), width: 1),
      ),
      titleTextStyle: TextStyle(
        color: Color(0xFFF8FAFC),
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: TextStyle(
        color: Color(0xFFCBD5E1),
        fontSize: 14,
        height: 1.5,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF334155),
      thickness: 1,
      space: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF0F172A),
      side: const BorderSide(color: Color(0xFF334155), width: 1),
      labelStyle: const TextStyle(
        color: Color(0xFFCBD5E1),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
    ),
  );

  /// 3. High-Contrast Theme (WCAG AAA Accessibility)
  /// Features:
  /// - Black background (#000000)
  /// - High-contrast pure white text (#FFFFFF)
  /// - Bright electric yellow (#FFE600) and cyan (#00E5FF) accents
  /// - Prominent 2.5px solid borders and explicit visual demarcation
  static final ThemeData highContrastTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFFFEA00), // Vibrant Electric Yellow A400
      onPrimary: Colors.black,
      primaryContainer: Colors.black,
      onPrimaryContainer: Color(0xFFFFEA00),
      secondary: Color(0xFF00E5FF), // Vibrant Cyan A400
      onSecondary: Colors.black,
      secondaryContainer: Colors.black,
      onSecondaryContainer: Color(0xFF00E5FF),
      tertiary: Color(0xFF00FF66), // High contrast neon green
      onTertiary: Colors.black,
      error: Color(0xFFFF1744), // Bright red
      onError: Colors.black,
      surface: Colors.black,
      onSurface: Colors.white,
      surfaceContainerHighest: Colors.black,
      outline: Color(0xFFFFEA00), // Yellow outlines
      outlineVariant: Color(0xFF00E5FF), // Cyan outlines
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: Colors.black,
      foregroundColor: Color(0xFFFFEA00),
      iconTheme: IconThemeData(color: Color(0xFFFFEA00), size: 24),
      titleTextStyle: TextStyle(
        color: Color(0xFFFFEA00),
        fontSize: 20,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
      shape: Border(
        bottom: BorderSide(color: Color(0xFFFFEA00), width: 2.5),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.black,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFFFEA00), width: 2.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xFFFFEA00),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.white, width: 2.0),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF00E5FF),
        side: const BorderSide(color: Color(0xFF00E5FF), width: 2.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFFFEA00),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          decoration: TextDecoration.underline,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.black,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFFEA00), width: 2.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFFEA00), width: 2.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 3.5),
      ),
      hintStyle: const TextStyle(
        color: Color(0xFFE2E8F0),
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      labelStyle: const TextStyle(
        color: Color(0xFFFFEA00),
        fontWeight: FontWeight.bold,
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.black,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: Color(0xFFFFEA00), width: 3.0),
      ),
      titleTextStyle: TextStyle(
        color: Color(0xFFFFEA00),
        fontSize: 22,
        fontWeight: FontWeight.w900,
      ),
      contentTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 15,
        height: 1.6,
        fontWeight: FontWeight.w500,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFFFEA00),
      thickness: 2.5,
      space: 2.5,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.black,
      side: const BorderSide(color: Color(0xFF00E5FF), width: 2.0),
      labelStyle: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: const Color(0xFFFFEA00), width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: const TextStyle(
        color: Color(0xFFFFEA00),
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  /// Helper to get ThemeData for a given AppTheme
  static ThemeData getThemeData(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return lightTheme;
      case AppTheme.dark:
        return darkTheme;
      case AppTheme.highContrast:
        return highContrastTheme;
    }
  }
}
