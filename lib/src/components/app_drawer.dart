import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final items = [
      _DrawerItem(
        label: 'Dashboard',
        route: '/home',
        icon: Icons.home_outlined,
        isSelected: currentRoute == '/home',
      ),
      _DrawerItem(
        label: 'Accounts',
        route: '/accounts',
        icon: Icons.account_balance_wallet_outlined,
        isSelected: currentRoute == '/accounts',
      ),
      _DrawerItem(
        label: 'Analysis',
        route: '/analysis',
        icon: Icons.pie_chart_outline,
        isSelected: currentRoute == '/analysis',
      ),
      _DrawerItem(
        label: 'Planner',
        route: '/planner',
        icon: Icons.track_changes_outlined,
        isSelected: currentRoute == '/planner',
      ),
      _DrawerItem(
        label: 'Calendar',
        route: '/calendar',
        icon: Icons.calendar_month_outlined,
        isSelected: currentRoute == '/calendar',
      ),
      _DrawerItem(
        label: 'Settings',
        route: '/settings',
        icon: Icons.settings_outlined,
        isSelected: currentRoute == '/settings',
      ),
    ];

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 12),
            Text(
              'Khoraise',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            ...items.map(
              (item) => ListTile(
                leading: Icon(item.icon),
                title: Text(item.label),
                selected: item.isSelected,
                selectedTileColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                onTap: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(item.route, (route) => false);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem {
  const _DrawerItem({
    required this.label,
    required this.route,
    required this.icon,
    required this.isSelected,
  });

  final String label;
  final String route;
  final IconData icon;
  final bool isSelected;
}
