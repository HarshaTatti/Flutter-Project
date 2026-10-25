import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/theme/app_themes.dart';
import 'package:flutter_application_1/theme/theme_controller.dart';
import 'package:flutter_application_1/widgets/theme_switcher.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('PrivacyChatbotApp smoke test and homepage rendering', (WidgetTester tester) async {
    final themeController = ThemeController();
    await themeController.loadTheme();

    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeController>.value(
        value: themeController,
        child: const PrivacyChatbotApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify AppBar title is present
    expect(find.text('Privacy-Preserving Chatbot'), findsWidgets);

    // Verify Hero text
    expect(find.text('Intelligent AI Assistance,\nCompletely Private.'), findsOneWidget);

    // Verify Start Chatting button
    expect(find.text('Start Chatting'), findsOneWidget);

    // Verify ThemeSwitcher is mounted
    expect(find.byType(ThemeSwitcher), findsWidgets);
  });

  testWidgets('Theme switching changes MaterialApp theme immediately', (WidgetTester tester) async {
    final themeController = ThemeController();
    await themeController.loadTheme();

    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeController>.value(
        value: themeController,
        child: const PrivacyChatbotApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Initial theme is light
    expect(themeController.currentTheme, AppTheme.light);

    // Switch to High Contrast
    await themeController.setTheme(AppTheme.highContrast);
    await tester.pumpAndSettle();

    expect(themeController.isHighContrast, isTrue);

    // Verify MaterialApp updated theme
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme?.scaffoldBackgroundColor, Colors.black);
  });
}
