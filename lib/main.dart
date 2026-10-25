import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/chat_screen.dart';
import 'screens/documents_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'services/local_data_service.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sample profile data if running for the first time
  final localDataService = LocalDataService();
  await localDataService.initializeSampleData();

  // Initialize theme controller and load persisted theme preference
  final themeController = ThemeController();
  await themeController.loadTheme();

  runApp(
    ChangeNotifierProvider<ThemeController>.value(
      value: themeController,
      child: const PrivacyChatbotApp(),
    ),
  );
}

class PrivacyChatbotApp extends StatelessWidget {
  const PrivacyChatbotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (context, themeController, child) {
        return MaterialApp(
          title: 'Privacy-Preserving Chatbot',
          debugShowCheckedModeBanner: false,
          theme: themeController.themeData,
          initialRoute: '/',
          routes: {
            '/': (context) => const HomeScreen(),
            '/chat': (context) => const ChatScreen(),
            '/documents': (context) => const DocumentsScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}
