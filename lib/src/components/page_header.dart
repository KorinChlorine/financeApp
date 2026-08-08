// src/components/page_header.dart
import 'package:flutter/material.dart';
import 'date_filter_selector.dart';

class PageHeader extends StatefulWidget implements PreferredSizeWidget {
  const PageHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(260);

  @override
  State<PageHeader> createState() => _PageHeaderState();
}

class _PageHeaderState extends State<PageHeader> {
  DateFilterMode _filterMode = DateFilterMode.daily;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AppBar(
      title: const Text('Khoraise'),
      foregroundColor: secondaryColor,
      backgroundColor: primaryColor,
      toolbarHeight: 120,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(15),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.menu, size: 35),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      ),
      actions: [
        PopupMenuButton<DateFilterMode>(
          icon: Icon(Icons.filter_list, color: secondaryColor, size: 32),
          onSelected: (mode) {
            setState(() {
              _filterMode = mode;
            });
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: DateFilterMode.daily, child: Text('Daily')),
            PopupMenuItem(value: DateFilterMode.weekly, child: Text('Weekly')),
            PopupMenuItem(value: DateFilterMode.monthly, child: Text('Monthly')),
            PopupMenuItem(value: DateFilterMode.yearly, child: Text('Yearly')),
          ],
        ),
        const SizedBox(width: 4),
        const Icon(Icons.search, size: 35),
        const SizedBox(width: 10),
      ],
      flexibleSpace: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(height: 80),
          DateFilterSelector(
            filterMode: _filterMode,
            onFilterChanged: (mode) {
              setState(() {
                _filterMode = mode;
              });
            },
          ),
          const SizedBox(height: 75),
        ],
      ),
    );
  }
}
