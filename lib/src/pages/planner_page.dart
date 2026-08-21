import 'package:flutter/material.dart';

import '../components/app_drawer.dart';
import '../components/date_filter_selector.dart';
import '../components/page_header.dart';
import '../models/finance_models.dart';
import '../services/finance_repository.dart';

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key, required this.repository});

  final FinanceRepository repository;

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  late DateTime _selectedMonth;

  FinanceRepository get repository => widget.repository;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthTransactions = repository.transactions.where((transaction) {
      return transaction.date.year == _selectedMonth.year && transaction.date.month == _selectedMonth.month;
    }).toList();
    final income = _sum(monthTransactions, TransactionType.income);
    final expenses = _sum(monthTransactions, TransactionType.expense);
    final categoryNames = {for (final category in repository.categories) category.id: category.name};
    final budgetStatuses = repository.budgets.map((budget) {
      final spent = repository.getBudgetUsageForCategory(budget.categoryId, referenceDate: _selectedMonth);
      return _BudgetStatus(
        name: categoryNames[budget.categoryId] ?? 'Category',
        spent: spent,
        limit: budget.limit,
      );
    }).toList();
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;
    final daysObserved = isCurrentMonth ? now.day : daysInMonth;
    final dailyAverage = daysObserved == 0 ? 0.0 : expenses / daysObserved;
    final projectedExpenses = dailyAverage * daysInMonth;
    final savingsRate = income <= 0 ? 0.0 : ((income - expenses) / income).clamp(-1.0, 1.0);

    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/planner'),
      appBar: PageHeader(
        filterMode: DateFilterMode.monthly,
        selectedDate: now,
        onFilterChanged: (_) {},
        onDateChanged: (_) {},
        income: income,
        expenses: expenses,
        showDateSelector: false,
        showTripleSummary: true,
        showSearch: false,
        showTodayAction: true,
        topPadding: 90,
        onTodayPressed: isCurrentMonth ? null : () => setState(() => _selectedMonth = DateTime(now.year, now.month)),
        dateLabel: _monthLabel(_selectedMonth),
        leftLabel: 'Income',
        rightLabel: 'Expenses',
        totalLabel: 'Available',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _MonthNavigator(
            month: _selectedMonth,
            onPrevious: () => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1)),
            onNext: isCurrentMonth
                ? null
                : () => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1)),
          ),
          const SizedBox(height: 14),
          _PlannerCard(
            title: 'Money pulse',
            icon: Icons.insights_outlined,
            child: Column(
              children: [
                _ProgressRow(
                  label: 'Spent this month',
                  value: expenses,
                  maximum: income <= 0 ? 1 : income,
                  color: expenses > income && income > 0 ? Colors.red.shade600 : Colors.orange.shade700,
                  repository: repository,
                ),
                const SizedBox(height: 14),
                _ProgressRow(
                  label: 'Available after expenses',
                  value: (income - expenses).clamp(0, double.infinity),
                  maximum: income <= 0 ? 1 : income,
                  color: Colors.green.shade700,
                  repository: repository,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _PlannerCard(
            title: 'Forecast',
            icon: Icons.auto_graph_outlined,
            child: Column(
              children: [
                _ForecastRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Daily average',
                  value: repository.formatCurrency(dailyAverage),
                  color: Colors.orange.shade700,
                ),
                const Divider(height: 20),
                _ForecastRow(
                  icon: Icons.trending_up_outlined,
                  label: 'Projected expenses',
                  value: repository.formatCurrency(projectedExpenses),
                  color: Colors.red.shade700,
                ),
                const Divider(height: 20),
                _ForecastRow(
                  icon: Icons.savings_outlined,
                  label: 'Savings rate',
                  value: '${(savingsRate * 100).toStringAsFixed(0)}%',
                  color: savingsRate >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _PlannerCard(
            title: 'Budget check',
            icon: Icons.track_changes_outlined,
            child: budgetStatuses.isEmpty
                ? const Text('Set a category budget to start tracking your plan.')
                : Column(
                    children: budgetStatuses.map((status) {
                      final ratio = status.limit <= 0 ? 0.0 : status.spent / status.limit;
                      final color = ratio > 1 ? Colors.red.shade700 : ratio >= 0.8 ? Colors.orange.shade700 : Colors.green.shade700;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(status.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text('${repository.formatCurrency(status.spent)} / ${repository.formatCurrency(status.limit)}', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                minHeight: 8,
                                value: ratio.clamp(0.0, 1.0),
                                backgroundColor: color.withValues(alpha: 0.14),
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  String _monthLabel(DateTime month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${names[month.month - 1]} ${month.year}';
  }

  double _sum(List<FinanceTransaction> transactions, TransactionType type) {
    return transactions.where((transaction) => transaction.type == type).fold(0, (sum, transaction) => sum + transaction.amount);
  }
}

class _BudgetStatus {
  const _BudgetStatus({required this.name, required this.spent, required this.limit});

  final String name;
  final double spent;
  final double limit;
}

class _MonthNavigator extends StatelessWidget {
  const _MonthNavigator({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            IconButton(onPressed: onPrevious, icon: const Icon(Icons.chevron_left), tooltip: 'Previous month'),
            Expanded(
              child: Text(
                _monthName(month),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right), tooltip: 'Next month'),
          ],
        ),
      ),
    );
  }

  String _monthName(DateTime date) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${names[date.month - 1]} ${date.year}';
  }
}

class _ForecastRow extends StatelessWidget {
  const _ForecastRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15)),
      ],
    );
  }
}

class _PlannerCard extends StatelessWidget {
  const _PlannerCard({required this.title, required this.icon, required this.child, this.centerTitle = false});

  final String title;
  final IconData icon;
  final Widget child;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: centerTitle ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.label, required this.value, required this.maximum, required this.color, required this.repository});

  final String label;
  final double value;
  final double maximum;
  final Color color;
  final FinanceRepository repository;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(repository.formatCurrency(value), style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 9,
            value: (value / maximum).clamp(0.0, 1.0),
            backgroundColor: color.withValues(alpha: 0.14),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}