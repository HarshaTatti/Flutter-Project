import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_themes.dart';

/// Manages active application theme with persistent storage
class ThemeController extends ChangeNotifier {
  static const String themePreferenceKey = 'selected_app_theme';

  AppTheme _currentTheme = AppTheme.light;
  bool _isInitialized = false;

  ThemeController() {
    loadTheme();
  }

  /// Current active theme
  AppTheme get currentTheme => _currentTheme;

  /// Whether controller has loaded saved preferences
  bool get isInitialized => _isInitialized;

  /// Returns the corresponding ThemeData for the current theme
  ThemeData get themeData => AppThemes.getThemeData(_currentTheme);

  /// Helper boolean getters
  bool get isLight => _currentTheme == AppTheme.light;
  bool get isDark => _currentTheme == AppTheme.dark;
  bool get isHighContrast => _currentTheme == AppTheme.highContrast;

  /// Current theme display name
  String get themeName => _currentTheme.displayName;

  /// Current theme icon
  IconData get themeIcon => _currentTheme.icon;

  /// Load persisted theme from SharedPreferences
  Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString(themePreferenceKey);
      if (savedKey != null) {
        _currentTheme = AppThemeExtension.fromKey(savedKey);
      }
    } catch (_) {
      // Fallback to light theme if storage fails
      _currentTheme = AppTheme.light;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Change active theme and save to local storage
  Future<void> setTheme(AppTheme theme) async {
    if (_currentTheme == theme) return;

    _currentTheme = theme;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(themePreferenceKey, theme.key);
    } catch (_) {
      // Non-fatal if saving fails
    }
  }

  /// Cycle to next theme (useful for quick toggling)
  Future<void> cycleTheme() async {
    switch (_currentTheme) {
      case AppTheme.light:
        await setTheme(AppTheme.dark);
        break;
      case AppTheme.dark:
        await setTheme(AppTheme.highContrast);
        break;
      case AppTheme.highContrast:
        await setTheme(AppTheme.light);
        break;
    }
  }
}
