// src/pages/dashboard.dart
import 'package:flutter/material.dart';
import '../components/date_filter_selector.dart';
import '../components/page_header.dart';
import '../components/transaction_detail_sheet.dart';
import '../components/transaction_form_sheet.dart';
import '../components/transaction_list_item.dart';
import '../components/app_drawer.dart';
import '../components/balances.dart';
import '../components/mini_bar_chart.dart';
import '../models/finance_models.dart';
import '../services/finance_repository.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final FinanceRepository _repository = financeRepository;
  DateFilterMode _filterMode = DateFilterMode.daily;
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _repository.addListener(_refresh);
  }

  @override
  void dispose() {
    _repository.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showAddTransactionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => TransactionFormSheet(
        repository: _repository,
        initialDate: _selectedDate,
      ),
    );
  }

  void _showTransactionDetails(FinanceTransaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => TransactionDetailSheet(
        transaction: transaction,
        repository: _repository,
      ),
    );
  }

  void _showSearchDialog() {
    final controller = TextEditingController(text: _searchQuery);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Search transactions'),
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

  List<double> _buildChartValues() {
    final values = <double>[];

    switch (_filterMode) {
      case DateFilterMode.daily:
        for (int index = 6; index >= 0; index--) {
          final date = _selectedDate.subtract(Duration(days: index));
          final total = _repository.transactions
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
          final weekStart = _selectedDate.subtract(Duration(days: 7 * index));
          final total = _repository.transactions.where((transaction) {
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
          final monthDate = DateTime(_selectedDate.year, _selectedDate.month - index, 1);
          final total = _repository.transactions.where((transaction) {
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
          final year = _selectedDate.year - index;
          final total = _repository.transactions.where((transaction) => transaction.date.year == year).fold<double>(0, (sum, transaction) {
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

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = _repository.transactions.where((transaction) {
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

    final chartValues = _buildChartValues();

    return Scaffold(
      drawer: const AppDrawer(
        currentRoute: '/home',
      ),
      appBar: PageHeader(
        filterMode: _filterMode,
        selectedDate: _selectedDate,
        onFilterChanged: (mode) {
          setState(() => _filterMode = mode);
        },
        onDateChanged: (date) {
          setState(() => _selectedDate = date);
        },
        income: totalIncome,
        expenses: totalExpenses,
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
                      Text('Cash flow', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 14),
                  MiniBarChart(
                    values: chartValues,
                    incomeColor: const Color(0xFF4F9D6C),
                    expenseColor: const Color(0xFFCE6D6D),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          UserBalance(income: totalIncome, expenses: totalExpenses),
          const SizedBox(height: 20),
          Row(
            children: [
              Text('Recent transactions', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(
                '${filteredTransactions.length} items',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (filteredTransactions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _searchQuery.isEmpty
                      ? 'No transactions yet. Tap the + button to add one.'
                      : 'No matches found for “$_searchQuery”.',
                ),
              ),
            )
          else
            ...filteredTransactions.map(
              (transaction) => TransactionListItem(
                transaction: transaction,
                onTap: () => _showTransactionDetails(transaction),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTransactionSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }
}
