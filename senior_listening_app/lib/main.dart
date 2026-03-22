import 'package:flutter/material.dart';

import 'screens/chat_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/rest_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SeniorListeningApp());
}

class SeniorListeningApp extends StatelessWidget {
  const SeniorListeningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '마음쉼터',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/chat': (_) => const ChatScreen(),
        '/history': (_) => const HistoryScreen(),
        '/rest': (_) => const RestScreen(),
      },
    );
  }
}
