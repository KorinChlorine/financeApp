
import 'package:flutter/material.dart';
import '../components/app_drawer.dart';
import '../components/date_filter_selector.dart';
import '../components/mini_bar_chart.dart';
import '../components/page_header.dart';
import '../models/finance_models.dart';
import '../services/finance_repository.dart';

class Analysis extends StatefulWidget {
  const Analysis({super.key, required this.repository});

  final FinanceRepository repository;

  @override
  State<Analysis> createState() => _AnalysisState();
}

List<double> buildAnalysisChartValues({
  required List<FinanceTransaction> transactions,
  required DateFilterMode filterMode,
  required DateTime selectedDate,
}) {
  final values = <double>[];

  switch (filterMode) {
    case DateFilterMode.daily:
      for (int index = 6; index >= 0; index--) {
        final date = selectedDate.subtract(Duration(days: index));
        final total = transactions
            .where((transaction) =>
                transaction.date.year == date.year &&
                transaction.date.month == date.month &&
                transaction.date.day == date.day)
            .fold<double>(0, (sum, transaction) {
              return transaction.type == TransactionType.expense
                  ? sum - transaction.amount
                  : sum + transaction.amount;
            });
        values.add(total);
      }
      break;
    case DateFilterMode.weekly:
      for (int index = 6; index >= 0; index--) {
        final weekStart = selectedDate.subtract(Duration(days: 7 * index));
        final total = transactions.where((transaction) {
          final currentWeekStart = weekStart.subtract(Duration(days: weekStart.weekday - 1));
          final currentWeekEnd = currentWeekStart.add(const Duration(days: 6));
          return transaction.date.isAfter(currentWeekStart.subtract(const Duration(days: 1))) &&
              transaction.date.isBefore(currentWeekEnd.add(const Duration(days: 1)));
        }).fold<double>(0, (sum, transaction) {
          return transaction.type == TransactionType.expense
              ? sum - transaction.amount
              : sum + transaction.amount;
        });
        values.add(total);
      }
      break;
    case DateFilterMode.monthly:
      for (int index = 5; index >= 0; index--) {
        final monthDate = DateTime(selectedDate.year, selectedDate.month - index, 1);
        final total = transactions.where((transaction) {
          return transaction.date.year == monthDate.year && transaction.date.month == monthDate.month;
        }).fold<double>(0, (sum, transaction) {
          return transaction.type == TransactionType.expense
              ? sum - transaction.amount
              : sum + transaction.amount;
        });
        values.add(total);
      }
      break;
    case DateFilterMode.yearly:
      for (int index = 6; index >= 0; index--) {
        final year = selectedDate.year - index;
        final total = transactions.where((transaction) => transaction.date.year == year).fold<double>(0, (sum, transaction) {
          return transaction.type == TransactionType.expense
              ? sum - transaction.amount
              : sum + transaction.amount;
        });
        values.add(total);
      }
      break;
  }

  return values;
}

class _AnalysisState extends State<Analysis> {
  DateFilterMode _filterMode = DateFilterMode.monthly;
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';

  void _showSearchDialog() {
    final controller = TextEditingController(text: _searchQuery);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Search analysis'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search by title or note',
            ),
            onSubmitted: (value) {
              setState(() => _searchQuery = value.trim());
              Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                setState(() => _searchQuery = controller.text.trim());
                Navigator.of(context).pop();
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = widget.repository.transactions.where((transaction) {
      final matchesText = _searchQuery.isEmpty ||
          transaction.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          transaction.note.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesDate = false;
      switch (_filterMode) {
        case DateFilterMode.daily:
          matchesDate = transaction.date.year == _selectedDate.year &&
              transaction.date.month == _selectedDate.month &&
              transaction.date.day == _selectedDate.day;
          break;
        case DateFilterMode.weekly:
          final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          matchesDate = transaction.date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
              transaction.date.isBefore(endOfWeek.add(const Duration(days: 1)));
          break;
        case DateFilterMode.monthly:
          matchesDate = transaction.date.year == _selectedDate.year &&
              transaction.date.month == _selectedDate.month;
          break;
        case DateFilterMode.yearly:
          matchesDate = transaction.date.year == _selectedDate.year;
          break;
      }
      return matchesDate && matchesText;
    }).toList();

    final totalIncome = filteredTransactions
        .where((transaction) => transaction.type == TransactionType.income)
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
    final totalExpenses = filteredTransactions
        .where((transaction) => transaction.type == TransactionType.expense)
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);

    final categoryBreakdown = <_CategorySummary>[];
    for (final category in widget.repository.categories) {
      final categoryTotal = filteredTransactions
          .where((transaction) => transaction.categoryId == category.id)
          .fold<double>(0, (sum, transaction) => sum + transaction.amount);
      if (categoryTotal > 0) {
        categoryBreakdown.add(_CategorySummary(category: category, total: categoryTotal));
      }
    }
    categoryBreakdown.sort((a, b) => b.total.compareTo(a.total));

    final topCategories = categoryBreakdown.take(5).toList();
    final chartValues = buildAnalysisChartValues(
      transactions: widget.repository.transactions,
      filterMode: _filterMode,
      selectedDate: _selectedDate,
    );
    final chartLabels = <String>[];
    switch (_filterMode) {
      case DateFilterMode.daily:
        for (int index = 6; index >= 0; index--) {
          final date = _selectedDate.subtract(Duration(days: index));
          chartLabels.add(date.day.toString());
        }
        break;
      case DateFilterMode.weekly:
        for (int index = 6; index >= 0; index--) {
          final weekStart = _selectedDate.subtract(Duration(days: 7 * index));
          final labelDate = weekStart.subtract(Duration(days: weekStart.weekday - 1));
          chartLabels.add('${labelDate.day}');
        }
        break;
      case DateFilterMode.monthly:
        for (int index = 5; index >= 0; index--) {
          final monthDate = DateTime(_selectedDate.year, _selectedDate.month - index, 1);
          chartLabels.add(_monthShort(monthDate.month));
        }
        break;
      case DateFilterMode.yearly:
        for (int index = 6; index >= 0; index--) {
          final year = _selectedDate.year - index;
          chartLabels.add(year.toString());
        }
        break;
    }
    final budgetCards = widget.repository.budgets.isEmpty
        ? const <Widget>[]
        : widget.repository.budgets.map((budget) {
            final spent = widget.repository.getBudgetUsageForCategory(budget.categoryId);
            final limit = widget.repository.getBudgetTotalForCategory(budget.categoryId);
            final categoryName = widget.repository.categories
                .firstWhere((category) => category.id == budget.categoryId,
                    orElse: () => TransactionCategory(
                        id: '',
                        name: 'Budget',
                        type: TransactionType.expense))
                .name;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          categoryName,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${spent.toStringAsFixed(0)} / ${limit.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: spent > limit ? const Color(0xFFCE6D6D) : const Color(0xFF4F9D6C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(999),
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      spent > limit ? const Color(0xFFCE6D6D) : const Color(0xFF4F9D6C),
                    ),
                  ),
                ],
              ),
            );
          }).toList();

    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/analysis'),
      appBar: PageHeader(
        filterMode: _filterMode,
        selectedDate: _selectedDate,
        onFilterChanged: (mode) => setState(() => _filterMode = mode),
        onDateChanged: (date) => setState(() => _selectedDate = date),
        income: totalIncome,
        expenses: totalExpenses,
        dateLabel: 'Analysis',
        showDateSelector: true,
        showTripleSummary: true,
        leftLabel: 'Income',
        rightLabel: 'Expenses',
        totalLabel: 'Net',
        topPadding: 75,
        onSearchPressed: _showSearchDialog,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (_searchQuery.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Search: $_searchQuery', overflow: TextOverflow.ellipsis),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _searchQuery = ''),
                    child: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.show_chart, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Flow overview', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  MiniBarChart(
                    values: chartValues,
                    labels: chartLabels,
                    incomeColor: const Color(0xFF4F9D6C),
                    expenseColor: const Color(0xFFCE6D6D),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _InsightCard(
            title: 'Net flow',
            value: (totalIncome - totalExpenses).toStringAsFixed(2),
            accent: const Color(0xFF4F9D6C),
          ),
          const SizedBox(height: 12),
          _InsightCard(
            title: 'Income',
            value: totalIncome.toStringAsFixed(2),
            accent: const Color(0xFF4F9D6C),
          ),
          const SizedBox(height: 12),
          _InsightCard(
            title: 'Expenses',
            value: totalExpenses.toStringAsFixed(2),
            accent: const Color(0xFFCE6D6D),
          ),
          const SizedBox(height: 20),
          Text('Top categories', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (topCategories.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No category activity in this range yet.'),
              ),
            )
          else
            ...topCategories.map(
              (summary) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summary.category.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            summary.category.type == TransactionType.expense ? 'Expense' : 'Income',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      summary.total.toStringAsFixed(2),
                      style: TextStyle(
                        color: summary.category.type == TransactionType.expense
                            ? const Color(0xFFCE6D6D)
                            : const Color(0xFF4F9D6C),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Income vs expense', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 160,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(6, (index) {
                        final date = DateTime.now().subtract(Duration(days: 5 - index));
                        final income = widget.repository.transactions
                            .where((transaction) =>
                                transaction.date.year == date.year &&
                                transaction.date.month == date.month &&
                                transaction.date.day == date.day &&
                                transaction.type == TransactionType.income)
                            .fold<double>(0, (sum, transaction) => sum + transaction.amount);
                        final expense = widget.repository.transactions
                            .where((transaction) =>
                                transaction.date.year == date.year &&
                                transaction.date.month == date.month &&
                                transaction.date.day == date.day &&
                                transaction.type == TransactionType.expense)
                            .fold<double>(0, (sum, transaction) => sum + transaction.amount);
                        final maxValue = [income, expense, 1.0].reduce((a, b) => a > b ? a : b);
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      width: 10,
                                      height: (income / maxValue * 90).clamp(8.0, 90.0),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4F9D6C),
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      width: 10,
                                      height: (expense / maxValue * 90).clamp(8.0, 90.0),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFCE6D6D),
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${date.day}',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _LegendDot(color: const Color(0xFF4F9D6C), label: 'Income'),
                      const SizedBox(width: 16),
                      _LegendDot(color: const Color(0xFFCE6D6D), label: 'Expense'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.pie_chart_outline, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Category share', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (topCategories.isEmpty)
                    Text('No category activity in this range yet.')
                  else
                    ...topCategories.map((summary) {
                      final total = topCategories.fold<double>(0, (sum, item) => sum + item.total);
                      final percent = total > 0 ? (summary.total / total) * 100 : 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(summary.category.name)),
                                Text('${percent.toStringAsFixed(0)}%'),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: percent / 100,
                                minHeight: 8,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  summary.category.type == TransactionType.expense
                                      ? const Color(0xFFCE6D6D)
                                      : const Color(0xFF4F9D6C),
                                ),
                                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Budgets', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (widget.repository.budgets.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No budgets set yet. Add one from the app settings flow to track spending.'),
              ),
            )
          else
            ...budgetCards,
          const SizedBox(height: 20),
          Text('Summary', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('This view is based on ${filteredTransactions.length} transaction(s) in the current period.'),
                  const SizedBox(height: 8),
                  Text(
                    totalExpenses > 0
                        ? 'You are spending ${((totalExpenses / (totalIncome + totalExpenses)) * 100).toStringAsFixed(0)}% of your current flow on expenses.'
                        : 'Your spending is currently low while income remains stable.',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _monthShort(int month) {
  const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return names[month - 1];
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.value,
    required this.accent,
  });

  final String title;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: accent.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: accent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}

class _CategorySummary {
  const _CategorySummary({
    required this.category,
    required this.total,
  });

  final TransactionCategory category;
  final double total;
}

