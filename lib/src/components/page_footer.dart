// src/components/page_footer.dart
import 'package:flutter/material.dart';

class PageFooter extends StatelessWidget {
  const PageFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(15), // 
        ),
      ),
      child: Center(
        child: Text(
          "© 2026 Khoraise",
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
