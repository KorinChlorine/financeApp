// src/pages/dashboard.dart
import 'package:flutter/material.dart';
import '../components/appBar.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarNav(), // black AppBar
      body: const Center(
        child: Text("Dashboard content here"),
      ),
      backgroundColor: Colors.grey[200], // optional: change page background
    );
  }
}
