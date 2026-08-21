import 'package:flutter/material.dart';

import '../components/app_drawer.dart';
import '../components/date_filter_selector.dart';
import '../components/page_header.dart';
import '../components/transaction_form_sheet.dart';
import '../models/finance_models.dart';
import '../services/finance_repository.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.repository});

  final FinanceRepository repository;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _selectedMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final transactions = widget.repository.transactions.where((transaction) {
      return transaction.date.year == _selectedMonth.year && transaction.date.month == _selectedMonth.month;
    }).toList();
    final dailyNet = <int, double>{};
    for (final transaction in transactions) {
      final signedAmount = transaction.type == TransactionType.income ? transaction.amount : -transaction.amount;
      dailyNet.update(transaction.date.day, (value) => value + signedAmount, ifAbsent: () => signedAmount);
    }
    final selectedTransactions = transactions.where((transaction) => transaction.date.day == _selectedDay.day).toList();
    final duePayments = widget.repository.recurringTransactions.where((transaction) {
      return transaction.nextDate.year == _selectedDay.year && transaction.nextDate.month == _selectedDay.month && transaction.nextDate.day == _selectedDay.day;
    }).toList();
    final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/calendar'),
      appBar: PageHeader(
        filterMode: DateFilterMode.monthly,
        selectedDate: _selectedMonth,
        onFilterChanged: (_) {},
        onDateChanged: (date) => _changeMonth(date),
        income: _sum(transactions, TransactionType.income),
        expenses: _sum(transactions, TransactionType.expense),
        showDateSelector: false,
        showTripleSummary: true,
        showSearch: false,
        showTodayAction: true,
        onTodayPressed: isCurrentMonth ? null : _goToToday,
        dateLabel: _monthLabel(_selectedMonth),
        topPadding: 90,
        leftLabel: 'Income',
        rightLabel: 'Expenses',
        totalLabel: 'Net flow',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 32),
        children: [
          _CalendarCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(onPressed: () => _changeMonth(DateTime(_selectedMonth.year, _selectedMonth.month - 1)), icon: const Icon(Icons.chevron_left), tooltip: 'Previous month'),
                    Text(_monthLabel(_selectedMonth), style: Theme.of(context).textTheme.titleMedium),
                    IconButton(onPressed: () => _changeMonth(DateTime(_selectedMonth.year, _selectedMonth.month + 1)), icon: const Icon(Icons.chevron_right), tooltip: 'Next month'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                      .map((day) => Expanded(child: Center(child: Text(day, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)))))
                      .toList(),
                ),
                const SizedBox(height: 6),
                _buildGrid(context, dailyNet),
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegendDot(color: Color(0xFF4F9D6C), label: 'Positive'),
                    SizedBox(width: 16),
                    _LegendDot(color: Color(0xFFCE6D6D), label: 'Negative'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _CalendarCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_selectedDay.day} ${_monthName(_selectedDay.month)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _addExpense(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add expense'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (selectedTransactions.isEmpty && duePayments.isEmpty)
                  const Text('Nothing recorded for this day.')
                else ...[
                  ...selectedTransactions.map((transaction) => _TransactionRow(transaction: transaction, repository: widget.repository)),
                  ...duePayments.map((payment) => _PaymentRow(payment: payment, repository: widget.repository)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _CalendarCard(
            child: Row(
              children: [
                Icon(Icons.payments_outlined, color: Colors.orange.shade700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    duePayments.isEmpty ? 'No scheduled payments on this day.' : '${duePayments.length} payment${duePayments.length == 1 ? '' : 's'} due on this day.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, Map<int, double> dailyNet) {
    final firstWeekday = DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday - 1;
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final cells = <Widget>[];
    for (var index = 0; index < firstWeekday; index++) {
      cells.add(const SizedBox());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final value = dailyNet[day] ?? 0;
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      final isSelected = date.year == _selectedDay.year && date.month == _selectedDay.month && date.day == _selectedDay.day;
      cells.add(
        GestureDetector(
          onTap: () => setState(() => _selectedDay = date),
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: value > 0
                  ? Colors.green.shade100
                  : value < 0
                      ? Colors.red.shade100
                      : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$day', style: const TextStyle(fontWeight: FontWeight.w700)),
                if (value != 0)
                  Icon(
                    value > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 14,
                    color: value > 0 ? Colors.green.shade700 : Colors.red.shade700,
                  ),
              ],
            ),
          ),
        ),
      );
    }
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.92,
      children: cells,
    );
  }

  Future<void> _addExpense(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TransactionFormSheet(
        repository: widget.repository,
        initialDate: _selectedDay,
      ),
    );
    if (mounted) setState(() {});
  }

  void _changeMonth(DateTime month) {
    setState(() {
      _selectedMonth = DateTime(month.year, month.month);
      final maxDay = DateTime(month.year, month.month + 1, 0).day;
      _selectedDay = DateTime(month.year, month.month, _selectedDay.day.clamp(1, maxDay));
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _selectedMonth = DateTime(now.year, now.month);
      _selectedDay = DateTime(now.year, now.month, now.day);
    });
  }

  double _sum(List<FinanceTransaction> transactions, TransactionType type) {
    return transactions.where((transaction) => transaction.type == type).fold(0, (sum, transaction) => sum + transaction.amount);
  }

  String _monthLabel(DateTime month) => '${_monthName(month.month)} ${month.year}';

  String _monthName(int month) {
    const names = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return names[month - 1];
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(padding: const EdgeInsets.all(14), child: child));
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction, required this.repository});

  final FinanceTransaction transaction;
  final FinanceRepository repository;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(isIncome ? Icons.arrow_upward : Icons.arrow_downward, color: isIncome ? Colors.green.shade700 : Colors.red.shade700),
      title: Text(transaction.title),
      subtitle: Text(transaction.note.isEmpty ? transaction.type.name : transaction.note),
      trailing: Text(repository.formatCurrency(transaction.amount), style: TextStyle(color: isIncome ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.w700)),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment, required this.repository});

  final RecurringTransaction payment;
  final FinanceRepository repository;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.event_repeat, color: Colors.orange.shade700),
      title: Text(payment.title),
      subtitle: const Text('Scheduled payment'),
      trailing: Text(repository.formatCurrency(payment.amount), style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w700)),
    );
  }
}
