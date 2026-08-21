import 'package:flutter/material.dart';
import 'src/pages/accounts_page.dart';
import 'src/pages/analysis.dart';
import 'src/pages/calendar_page.dart';
import 'src/pages/dashboard.dart';
import 'src/pages/planner_page.dart';
import 'src/pages/settings_page.dart';
import 'src/services/finance_repository.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Khoraise',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFE9DDCB),
        cardTheme: CardThemeData(
          color: const Color(0xFFF3EAE0),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF977B5E),
          onPrimary: Color(0xFFF9F5F0),
          secondary: Color(0xFFE9DCC7),
          onSecondary: Color(0xFF5D4A39),
          error: Color(0xFFCE6D6D),
          onError: Color(0xFFFDF3F3),
          surface: Color(0xFFE9DDCB),
          onSurface: Color(0xFF4E3C2F),
          tertiary: Color(0xFF4F9D6C),
          onTertiary: Color(0xFFF1F9F4),
        ),
        fontFamily: 'Poppins',
        textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Poppins').copyWith(
          displayLarge: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4E3C2F),
          ),
          titleLarge: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4E3C2F),
          ),
          titleMedium: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4E3C2F),
          ),
          bodyMedium: const TextStyle(
            fontSize: 16,
            color: Color(0xFF4E3C2F),
          ),
          bodySmall: const TextStyle(
            fontSize: 14,
            color: Color(0xFF4E3C2F),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      routes: {
        '/home': (context) => const Dashboard(),
        '/accounts': (context) => AccountsPage(repository: financeRepository),
        '/analysis': (context) => Analysis(repository: financeRepository),
        '/calendar': (context) => CalendarPage(repository: financeRepository),
        '/planner': (context) => PlannerPage(repository: financeRepository),
        '/settings': (context) => SettingsPage(repository: financeRepository),
      },
      home: const Dashboard(),
    );
  }
}