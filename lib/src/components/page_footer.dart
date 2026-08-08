// src/components/page_footer.dart
import 'package:flutter/material.dart';

class PageFooter extends StatelessWidget {
  const PageFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
            },
            icon: const Icon(Icons.home_outlined),
            color: Theme.of(context).colorScheme.secondary,
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/accounts');
            },
            icon: const Icon(Icons.account_balance_wallet_outlined),
            color: Theme.of(context).colorScheme.secondary,
          ),
        ],
      ),
    );
  }
}
