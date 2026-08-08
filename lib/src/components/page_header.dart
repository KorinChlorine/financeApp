// src/components/page_header.dart
import 'package:flutter/material.dart';

class PageHeader extends StatelessWidget implements PreferredSizeWidget {
  const PageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Khoraise'),
      foregroundColor: Theme.of(context).colorScheme.secondary,
      backgroundColor: Theme.of(context).colorScheme.primary,
      toolbarHeight: 120,
      shape: const  RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(15),
        )
      )
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(220);
}
