// src/pages/dashboard.dart
import 'package:flutter/material.dart';
import '../components/page_header.dart';
import '../components/page_footer.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageHeader(),
      body: const Center(
        child: Text("Description"),

      ),
      backgroundColor: Theme.of(context).colorScheme.surface, 
      bottomNavigationBar: const PageFooter(),
    );
  }
}
