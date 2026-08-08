// src/components/page_header.dart
import 'package:flutter/material.dart';
import 'date_filter_selector.dart';
import 'balances.dart';

class PageHeader extends StatefulWidget implements PreferredSizeWidget {
  const PageHeader({
    super.key,
    required this.filterMode,
    required this.selectedDate,
    required this.onFilterChanged,
    required this.onDateChanged,
    required this.income,
    required this.expenses,
    this.showDateSelector = true,
    this.dateLabel = 'All Accounts',
    this.showDualSummaryLabels = false,
    this.showTripleSummary = false,
    this.leftLabel = 'Expenses so far',
    this.rightLabel = 'Income so far',
    this.totalLabel = 'Total',
  });

  final DateFilterMode filterMode;
  final DateTime selectedDate;
  final ValueChanged<DateFilterMode> onFilterChanged;
  final ValueChanged<DateTime> onDateChanged;
  final double income;
  final double expenses;
  final bool showDateSelector;
  final String dateLabel;
  final bool showDualSummaryLabels;
  final bool showTripleSummary;
  final String leftLabel;
  final String rightLabel;
  final String totalLabel;

  @override
  Size get preferredSize => const Size.fromHeight(260);

  @override
  State<PageHeader> createState() => _PageHeaderState();
}

class _PageHeaderState extends State<PageHeader> {

  @override
  Widget build(BuildContext context) {
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AppBar(
      title: const Text('Khoraise'),
      foregroundColor: secondaryColor,
      backgroundColor: primaryColor,
      toolbarHeight: 120, // matches preferredSize now
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
        if (widget.showDateSelector)
          PopupMenuButton<DateFilterMode>(
            icon: Icon(Icons.filter_list, color: secondaryColor, size: 32),
            onSelected: (mode) {
              widget.onFilterChanged(mode);
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
          const SizedBox(height: 90),
          if (widget.showDateSelector)
            DateFilterSelector(
              filterMode: widget.filterMode,
              onFilterChanged: widget.onFilterChanged,
              selectedDate: widget.selectedDate,
              onDateChanged: widget.onDateChanged,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: secondaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                widget.dateLabel,
                style: TextStyle(
                  color: secondaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 14),
          if (widget.showTripleSummary)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _HeaderSummaryItem(
                      label: widget.leftLabel,
                      value: widget.income,
                      color: secondaryColor,
                    ),
                  ),
                  Expanded(
                    child: _HeaderSummaryItem(
                      label: widget.rightLabel,
                      value: widget.expenses,
                      color: secondaryColor,
                    ),
                  ),
                  Expanded(
                    child: _HeaderSummaryItem(
                      label: widget.totalLabel,
                      value: widget.income - widget.expenses,
                      color: secondaryColor,
                    ),
                  ),
                ],
              ),
            )
          else if (widget.showDualSummaryLabels)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.leftLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.rightLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          if (!widget.showTripleSummary)
            UserBalance(income: widget.income, expenses: widget.expenses),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _HeaderSummaryItem extends StatelessWidget {
  const _HeaderSummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(2),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}