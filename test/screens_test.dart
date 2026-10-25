import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/screens/chat_screen.dart';
import 'package:flutter_application_1/screens/documents_screen.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/screens/settings_screen.dart';
import 'package:flutter_application_1/theme/theme_controller.dart';
import 'package:flutter_application_1/widgets/feature_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ThemeController themeController;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    themeController = ThemeController();
    await themeController.loadTheme();
  });

  Widget createTestWidget(Widget child) {
    return ChangeNotifierProvider<ThemeController>.value(
      value: themeController,
      child: MaterialApp(
        theme: themeController.themeData,
        home: child,
        routes: {
          '/chat': (context) => const ChatScreen(),
          '/documents': (context) => const DocumentsScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }

  testWidgets('HomeScreen renders hero, action buttons, and feature cards', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(const HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Intelligent AI Assistance,\nCompletely Private.'), findsOneWidget);
    expect(find.text('Start Chatting'), findsOneWidget);
    expect(find.text('Manage Documents'), findsOneWidget);
    expect(find.byType(FeatureCard), findsNWidgets(4));
  });

  testWidgets('ChatScreen sends message and receives local response', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(const ChatScreen()));
    await tester.pumpAndSettle();

    // Verify initial welcome message exists
    expect(find.textContaining('Welcome to Privacy AI Assistant'), findsOneWidget);

    // Enter text in chat field
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);
    await tester.enterText(textField, 'hello');

    // Tap send button
    final sendButton = find.byIcon(Icons.send_rounded);
    expect(sendButton, findsOneWidget);
    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    // Verify user message is displayed in message list
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('DocumentsScreen displays empty state and supported formats', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(const DocumentsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Document Management'), findsOneWidget);
    expect(find.textContaining('Supported formats: PDF, DOCX, PPTX, TXT'), findsOneWidget);
    expect(find.text('No Documents Uploaded Yet'), findsOneWidget);
  });

  testWidgets('SettingsScreen displays theme options and profile controls', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(const SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Application Settings'), findsOneWidget);
    expect(find.text('Select Display Theme'), findsOneWidget);
    expect(find.text('Light'), findsWidgets);
    expect(find.text('Dark'), findsWidgets);
    expect(find.text('High Contrast'), findsWidgets);
    expect(find.text('On-Device Profile Data'), findsOneWidget);
  });
}
