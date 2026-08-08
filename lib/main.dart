import 'package:flutter/material.dart';
import 'src/pages/dashboard.dart';
import 'src/pages/analysis.dart';
import 'src/components/appBar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      debugShowCheckedModeBanner: false,
      home: const Dashboard(), // starts on Dashboard
    );
  }
}
