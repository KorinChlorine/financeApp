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
    this.onSearchPressed,
    this.headerControl,
    this.topPadding = 72,
    this.showSearch = true,
    this.headerHeight = 240,
    this.toolbarHeight = 86,
    this.showBalance = true,
    this.showTodayAction = false,
    this.onTodayPressed,
    this.currencySymbol = '\$',
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
  final VoidCallback? onSearchPressed;
  final Widget? headerControl;
  final double topPadding;
  final bool showSearch;
  final double headerHeight;
  final double toolbarHeight;
  final bool showBalance;
  final bool showTodayAction;
  final VoidCallback? onTodayPressed;
  final String currencySymbol;

  @override
  Size get preferredSize => Size.fromHeight(headerHeight);

  @override
  State<PageHeader> createState() => _PageHeaderState();
}

class _PageHeaderState extends State<PageHeader> {

  @override
  Widget build(BuildContext context) {
    final secondaryColor = Theme.of(context).colorScheme.onPrimary;
    final primaryColor = const Color(0xFF4B362D);
    final summarySurface = const Color(0xFFE9DFD4);
    final summaryBorder = const Color(0xFF765F4E);

    return AppBar(
      title: const Text('Khoraise'),
      foregroundColor: secondaryColor,
      backgroundColor: primaryColor,
      toolbarHeight: widget.toolbarHeight,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(18),
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
        if (widget.showSearch)
          IconButton(
            onPressed: widget.onSearchPressed ?? () {},
            icon: const Icon(Icons.search, size: 35),
            color: secondaryColor,
          ),
        if (widget.showTodayAction)
          IconButton(
            onPressed: widget.onTodayPressed,
            icon: const Icon(Icons.today_outlined, size: 28),
            color: secondaryColor,
            tooltip: 'Today',
          ),
        const SizedBox(width: 10),
      ],
      flexibleSpace: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: widget.topPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showDateSelector)
                DateFilterSelector(
                  filterMode: widget.filterMode,
                  onFilterChanged: widget.onFilterChanged,
                  selectedDate: widget.selectedDate,
                  onDateChanged: widget.onDateChanged,
                )
              else if (widget.headerControl != null)
                widget.headerControl!
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: summarySurface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: summaryBorder.withValues(alpha: 0.18)),
                  ),
                  child: Text(
                    widget.dateLabel,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              if (widget.showTripleSummary)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: summarySurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: summaryBorder.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _HeaderSummaryItem(
                            label: widget.leftLabel,
                            value: widget.income,
                            color: const Color(0xFF4B362D),
                            currencySymbol: widget.currencySymbol,
                          ),
                        ),
                        Expanded(
                          child: _HeaderSummaryItem(
                            label: widget.rightLabel,
                            value: widget.expenses,
                            color: const Color(0xFFB85D5D),
                            currencySymbol: widget.currencySymbol,
                          ),
                        ),
                        Expanded(
                          child: _HeaderSummaryItem(
                            label: widget.totalLabel,
                            value: widget.income - widget.expenses,
                            color: const Color(0xFF3B7A56),
                            currencySymbol: widget.currencySymbol,
                          ),
                        ),
                      ],
                    ),
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
              const SizedBox(height: 6),
              if (!widget.showTripleSummary && widget.showBalance)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: UserBalance(income: widget.income, expenses: widget.expenses, currencySymbol: widget.currencySymbol),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderSummaryItem extends StatelessWidget {
  const _HeaderSummaryItem({
    required this.label,
    required this.value,
    required this.color,
    required this.currencySymbol,
  });

  final String label;
  final double value;
  final Color color;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color.withValues(alpha: 0.82),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${currencySymbol}${value.toStringAsFixed(2)}',
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