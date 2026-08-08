import 'package:flutter/material.dart';

enum DateFilterMode { daily, weekly, monthly, yearly }

class DateFilterSelector extends StatefulWidget {
  const DateFilterSelector({
    super.key,
    required this.filterMode,
    required this.onFilterChanged,
    required this.selectedDate,
    required this.onDateChanged,
  });

  final DateFilterMode filterMode;
  final ValueChanged<DateFilterMode> onFilterChanged;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  @override
  State<DateFilterSelector> createState() => _DateFilterSelectorState();
}

class _DateFilterSelectorState extends State<DateFilterSelector> {

  void _changeDate(int offset) {
    DateTime nextDate;
    switch (widget.filterMode) {
      case DateFilterMode.daily:
        nextDate = widget.selectedDate.add(const Duration(days: 1) * offset);
        break;
      case DateFilterMode.weekly:
        nextDate = widget.selectedDate.add(const Duration(days: 7) * offset);
        break;
      case DateFilterMode.monthly:
        nextDate = DateTime(widget.selectedDate.year, widget.selectedDate.month + offset);
        break;
      case DateFilterMode.yearly:
        nextDate = DateTime(widget.selectedDate.year + offset, widget.selectedDate.month);
        break;
    }
    widget.onDateChanged(nextDate);
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      widget.onDateChanged(pickedDate);
    }
  }

  String _formatLabel() {
    switch (widget.filterMode) {
      case DateFilterMode.daily:
        return '${_weekdayName(widget.selectedDate.weekday)}, ${widget.selectedDate.day} ${_monthName(widget.selectedDate.month)} ${widget.selectedDate.year}';
      case DateFilterMode.weekly:
        final startOfWeek = widget.selectedDate.subtract(Duration(days: widget.selectedDate.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${_monthName(startOfWeek.month)} ${startOfWeek.day} - ${_monthName(endOfWeek.month)} ${endOfWeek.day}, ${startOfWeek.year}';
      case DateFilterMode.monthly:
        return '${_monthName(widget.selectedDate.month)} ${widget.selectedDate.year}';
      case DateFilterMode.yearly:
        return '${widget.selectedDate.year}';
    }
  }

  String _weekdayName(int weekday) {
    const names = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[weekday - 1];
  }

  String _monthName(int month) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_left, size: 40),
          color: color,
          onPressed: () => _changeDate(-1),
        ),
        GestureDetector(
          onTap: _pickDate,
          child: Column(
            children: [
              Text(
                _formatLabel(),
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_right, size: 40),
          color: color,
          onPressed: () => _changeDate(1),
        ),
      ],
    );
  }
}
