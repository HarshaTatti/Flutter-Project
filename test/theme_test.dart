import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/theme/app_themes.dart';
import 'package:flutter_application_1/theme/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTheme & AppThemes Definition Tests', () {
    test('Verify Light Theme definitions', () {
      final theme = AppThemes.lightTheme;
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, const Color(0xFF4F46E5));
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF8FAFC));
      expect(theme.cardTheme.color, Colors.white);
    });

    test('Verify Dark Theme definitions', () {
      final theme = AppThemes.darkTheme;
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, const Color(0xFF6366F1));
      expect(theme.scaffoldBackgroundColor, const Color(0xFF0B0F19));
      expect(theme.cardTheme.color, const Color(0xFF1E293B));
    });

    test('Verify High-Contrast Theme definitions (WCAG AAA)', () {
      final theme = AppThemes.highContrastTheme;
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, Colors.black);
      expect(theme.colorScheme.surface, Colors.black);
      expect(theme.colorScheme.onSurface, Colors.white);
      expect(theme.colorScheme.primary, const Color(0xFFFFEA00));
      expect(theme.colorScheme.secondary, const Color(0xFF00E5FF));
      expect(theme.cardTheme.color, Colors.black);
    });

    test('Verify High-Contrast Theme is distinct from Dark Theme', () {
      final dark = AppThemes.darkTheme;
      final highContrast = AppThemes.highContrastTheme;

      // Must be fundamentally different configurations, not synonyms
      expect(highContrast.scaffoldBackgroundColor, isNot(equals(dark.scaffoldBackgroundColor)));
      expect(highContrast.colorScheme.primary, isNot(equals(dark.colorScheme.primary)));
      expect(highContrast.colorScheme.surface, isNot(equals(dark.colorScheme.surface)));
      expect(highContrast.cardTheme.color, isNot(equals(dark.cardTheme.color)));
    });

    test('AppTheme keys and extension mappings', () {
      expect(AppTheme.light.key, 'light');
      expect(AppTheme.dark.key, 'dark');
      expect(AppTheme.highContrast.key, 'high_contrast');

      expect(AppThemeExtension.fromKey('light'), AppTheme.light);
      expect(AppThemeExtension.fromKey('dark'), AppTheme.dark);
      expect(AppThemeExtension.fromKey('high_contrast'), AppTheme.highContrast);
      expect(AppThemeExtension.fromKey('unknown'), AppTheme.light);
    });
  });

  group('ThemeController State & Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('ThemeController defaults to Light theme', () async {
      final controller = ThemeController();
      await controller.loadTheme();

      expect(controller.currentTheme, AppTheme.light);
      expect(controller.isLight, isTrue);
      expect(controller.isDark, isFalse);
      expect(controller.isHighContrast, isFalse);
    });

    test('ThemeController transitions to Dark and High-Contrast', () async {
      final controller = ThemeController();
      await controller.loadTheme();

      bool listenerNotified = false;
      controller.addListener(() => listenerNotified = true);

      // Switch to Dark
      await controller.setTheme(AppTheme.dark);
      expect(controller.currentTheme, AppTheme.dark);
      expect(controller.isDark, isTrue);
      expect(listenerNotified, isTrue);

      // Switch to High Contrast
      listenerNotified = false;
      await controller.setTheme(AppTheme.highContrast);
      expect(controller.currentTheme, AppTheme.highContrast);
      expect(controller.isHighContrast, isTrue);
      expect(listenerNotified, isTrue);

      // Verify persistence in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ThemeController.themePreferenceKey), 'high_contrast');
    });

    test('ThemeController loads saved High-Contrast preference on startup', () async {
      SharedPreferences.setMockInitialValues({
        ThemeController.themePreferenceKey: 'high_contrast',
      });

      final controller = ThemeController();
      await controller.loadTheme();

      expect(controller.currentTheme, AppTheme.highContrast);
      expect(controller.isHighContrast, isTrue);
      expect(controller.themeData.scaffoldBackgroundColor, Colors.black);
    });

    test('ThemeController cycleTheme works circularly', () async {
      final controller = ThemeController();
      await controller.loadTheme();
      expect(controller.currentTheme, AppTheme.light);

      await controller.cycleTheme();
      expect(controller.currentTheme, AppTheme.dark);

      await controller.cycleTheme();
      expect(controller.currentTheme, AppTheme.highContrast);

      await controller.cycleTheme();
      expect(controller.currentTheme, AppTheme.light);
    });
  });
}
