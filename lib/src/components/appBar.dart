// src/components/app_bar_nav.dart
import 'package:flutter/material.dart';

class AppBarNav extends StatelessWidget implements PreferredSizeWidget {
  const AppBarNav({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text("Budgeter"),
      backgroundColor: Colors.black, // only affects the AppBar
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
