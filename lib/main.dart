import 'package:flutter/material.dart';
import 'src/pages/dashboard.dart';

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
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF977B5E),
          onPrimary: Color.fromARGB(255, 255, 242, 221),
          secondary: Color.fromARGB(255, 255, 242, 221),
          onSecondary: Color(0xFF977B5E),
          error: Color(0xFF977B5E),
          onError: Color.fromARGB(255, 255, 242, 221),
          surface: Color.fromARGB(255, 255, 242, 221),
          onSurface: Color(0xFF977B5E),
        ),
        fontFamily: 'Poppins',
        textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Poppins').copyWith(
          displayLarge: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: Color(0xFF977B5E),
          ),
          titleLarge: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w600,
            color: Color(0xFF977B5E),
          ),
          bodyMedium: const TextStyle(
            fontSize: 16,
            color: Color(0xFF977B5E),
          ),
          bodySmall: const TextStyle(
            fontSize: 14,
            color: Color(0xFF977B5E),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const Dashboard(),
    );
  }
}