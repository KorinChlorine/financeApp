import 'package:flutter/material.dart';
import '../models/finance_models.dart';

class FinanceRepository extends ChangeNotifier {
  FinanceRepository() {
    _accounts.addAll([
      Account(id: 'cash', name: 'Cash'),
      Account(id: 'bank', name: 'Bank Account'),
    ]);

    _categories.addAll([
      TransactionCategory(id: 'salary', name: 'Salary', type: TransactionType.income),
      TransactionCategory(id: 'freelance', name: 'Freelance', type: TransactionType.income),
      TransactionCategory(id: 'food', name: 'Food', type: TransactionType.expense),
      TransactionCategory(id: 'transport', name: 'Transport', type: TransactionType.expense),
      TransactionCategory(id: 'rent', name: 'Rent', type: TransactionType.expense),
      TransactionCategory(id: 'shopping', name: 'Shopping', type: TransactionType.expense),
      TransactionCategory(id: 'utilities', name: 'Utilities', type: TransactionType.expense),
      TransactionCategory(id: 'other-income', name: 'Other Income', type: TransactionType.income),
      TransactionCategory(id: 'other-expense', name: 'Other Expense', type: TransactionType.expense),
    ]);
  }

  final List<Account> _accounts = <Account>[];
  final List<TransactionCategory> _categories = <TransactionCategory>[];
  final List<FinanceTransaction> _transactions = <FinanceTransaction>[];

  List<Account> get accounts => List.unmodifiable(_accounts);
  List<TransactionCategory> get categories => List.unmodifiable(_categories);
  List<FinanceTransaction> get transactions => List.unmodifiable(_transactions);

  List<FinanceTransaction> get recentTransactions => List.unmodifiable(_transactions.reversed.toList());

  double get totalIncome {
    return _transactions
        .where((transaction) => transaction.type == TransactionType.income)
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
  }

  double get totalExpenses {
    return _transactions
        .where((transaction) => transaction.type == TransactionType.expense)
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
  }

  double get balance => totalIncome - totalExpenses;

  void addAccount(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return;
    }

    _accounts.add(Account(id: 'account_${DateTime.now().millisecondsSinceEpoch}', name: trimmedName));
    notifyListeners();
  }

  void addCategory(TransactionType type, String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return;
    }

    _categories.add(
      TransactionCategory(
        id: 'category_${DateTime.now().millisecondsSinceEpoch}',
        name: trimmedName,
        type: type,
      ),
    );
    notifyListeners();
  }

  void addTransaction(FinanceTransaction transaction) {
    _transactions.add(transaction);
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  void updateTransaction(FinanceTransaction updatedTransaction) {
    final index = _transactions.indexWhere((transaction) => transaction.id == updatedTransaction.id);
    if (index >= 0) {
      _transactions[index] = updatedTransaction;
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    }
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((transaction) => transaction.id == id);
    notifyListeners();
  }
}

final financeRepository = FinanceRepository();
