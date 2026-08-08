// src/pages/dashboard.dart
import 'package:flutter/material.dart';
import '../components/date_filter_selector.dart';
import '../components/page_footer.dart';
import '../components/page_header.dart';
import '../components/transaction_detail_sheet.dart';
import '../components/transaction_form_sheet.dart';
import '../components/transaction_list_item.dart';
import '../components/balances.dart';
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

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = _repository.transactions.where((transaction) {
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
      return matchesDate;
    }).toList();

    final totalIncome = filteredTransactions
        .where((transaction) => transaction.type == TransactionType.income)
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
    final totalExpenses = filteredTransactions
        .where((transaction) => transaction.type == TransactionType.expense)
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);

    return Scaffold(
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
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          UserBalance(income: totalIncome, expenses: totalExpenses),
          const SizedBox(height: 20),
          Text('Recent transactions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (filteredTransactions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('No transactions yet. Tap the + button to add one.'),
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
      bottomNavigationBar: const PageFooter(),
    );
  }
}
