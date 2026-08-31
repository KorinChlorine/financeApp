import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/finance_models.dart';

class FinanceRepository extends ChangeNotifier {
  FinanceRepository() {
    _accounts.addAll([
      Account(id: 'cash', name: 'Cash'),
      Account(id: 'savings', name: 'Savings'),
    ]);

    _categories.addAll([
      TransactionCategory(id: 'salary', name: 'Salary', type: TransactionType.income),
      TransactionCategory(id: 'bonus', name: 'Bonus', type: TransactionType.income),
      TransactionCategory(id: 'food', name: 'Food', type: TransactionType.expense),
      TransactionCategory(id: 'transport', name: 'Transport', type: TransactionType.expense),
      TransactionCategory(id: 'shopping', name: 'Shopping', type: TransactionType.expense),
      TransactionCategory(id: 'education', name: 'Education', type: TransactionType.expense),
      TransactionCategory(id: 'other-income', name: 'Other Income', type: TransactionType.income),
      TransactionCategory(id: 'other-expense', name: 'Other Expense', type: TransactionType.expense),
    ]);

    ready = _loadPersistedData();
  }

  final List<Account> _accounts = <Account>[];
  final List<TransactionCategory> _categories = <TransactionCategory>[];
  final List<FinanceTransaction> _transactions = <FinanceTransaction>[];
  final List<Budget> _budgets = <Budget>[];
  final List<RecurringTransaction> _recurringTransactions = <RecurringTransaction>[];
  AppSettings _settings = const AppSettings();
  late final Future<void> ready;
  Future<void> _persistenceQueue = Future<void>.value();

  List<Account> get accounts => List.unmodifiable(_accounts);
  List<TransactionCategory> get categories => List.unmodifiable(_categories);
  List<FinanceTransaction> get transactions => List.unmodifiable(_transactions);
  List<Budget> get budgets => List.unmodifiable(_budgets);
  List<RecurringTransaction> get recurringTransactions => List.unmodifiable(_recurringTransactions);
  AppSettings get settings => _settings;

  List<FinanceTransaction> get recentTransactions => List.unmodifiable(_transactions.reversed.toList());

  String get currencyCode => _settings.currencyCode;
  String get currencySymbol => _settings.currencySymbol;

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

  String formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(2);
    return '${_settings.currencySymbol}$formatted';
  }

  Future<void> setCurrencyCode(String currencyCode) async {
    final normalized = currencyCode.trim();
    if (normalized.isEmpty) {
      return;
    }

    final code = normalized.toUpperCase();
    if (code != 'PHP' && code != 'USD') {
      return;
    }

    final symbol = switch (code) {
      'PHP' => '₱',
      _ => '\$',
    };

    _settings = _settings.copyWith(
      currencyCode: code,
      currencySymbol: symbol,
    );
    await _persistSettings();
    notifyListeners();
  }

  void updateSettings(AppSettings settings) {
    _settings = settings;
    _persistSettings();
    notifyListeners();
  }

  Future<void> resetApp() async {
    _accounts
      ..clear()
      ..addAll([
        Account(id: 'cash', name: 'Cash'),
        Account(id: 'savings', name: 'Savings'),
      ]);
    _categories
      ..clear()
      ..addAll([
        TransactionCategory(id: 'salary', name: 'Salary', type: TransactionType.income),
        TransactionCategory(id: 'bonus', name: 'Bonus', type: TransactionType.income),
        TransactionCategory(id: 'food', name: 'Food', type: TransactionType.expense),
        TransactionCategory(id: 'transport', name: 'Transport', type: TransactionType.expense),
        TransactionCategory(id: 'shopping', name: 'Shopping', type: TransactionType.expense),
        TransactionCategory(id: 'education', name: 'Education', type: TransactionType.expense),
        TransactionCategory(id: 'other-income', name: 'Other Income', type: TransactionType.income),
        TransactionCategory(id: 'other-expense', name: 'Other Expense', type: TransactionType.expense),
      ]);
    _transactions.clear();
    _budgets.clear();
    _recurringTransactions.clear();
    _settings = const AppSettings();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('khoraise_settings');
    await prefs.remove('khoraise_data');
    notifyListeners();
  }

  void addAccount(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return;
    }

    _accounts.add(Account(id: 'account_${DateTime.now().millisecondsSinceEpoch}', name: trimmedName));
    _persistData();
    notifyListeners();
  }

  void removeAccount(String id) {
    if (id.isEmpty) {
      return;
    }

    _accounts.removeWhere((account) => account.id == id);
    _transactions.removeWhere((transaction) => transaction.accountId == id);
    _persistData();
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
    _persistData();
    notifyListeners();
  }

  void removeCategory(String id) {
    if (id.isEmpty) {
      return;
    }

    _categories.removeWhere((category) => category.id == id);
    _transactions.removeWhere((transaction) => transaction.categoryId == id);
    _budgets.removeWhere((budget) => budget.categoryId == id);
    _persistData();
    notifyListeners();
  }

  void addBudgetForCategory(String categoryId, double limit, BudgetPeriod period, DateTime startDate) {
    if (categoryId.isEmpty || limit <= 0) {
      return;
    }

    final category = _categories.where((item) => item.id == categoryId).isNotEmpty
        ? _categories.firstWhere((item) => item.id == categoryId)
        : null;
    if (category == null || category.type != TransactionType.expense) {
      return;
    }

    final existingIndex = _budgets.indexWhere((budget) => budget.categoryId == categoryId);
    if (existingIndex >= 0) {
      _budgets[existingIndex] = _budgets[existingIndex].copyWith(
        limit: limit,
        period: period,
        startDate: startDate,
      );
    } else {
      _budgets.add(
        Budget(
          id: 'budget_${DateTime.now().millisecondsSinceEpoch}',
          categoryId: categoryId,
          limit: limit,
          period: period,
          startDate: startDate,
        ),
      );
    }
    _persistData();
    notifyListeners();
  }

  void addTransaction(FinanceTransaction transaction) {
    _transactions.add(transaction);
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    _persistData();
    notifyListeners();
  }

  void addBudget(Budget budget) {
    _budgets.add(budget);
    _persistData();
    notifyListeners();
  }

  void removeBudget(String id) {
    _budgets.removeWhere((budget) => budget.id == id);
    _persistData();
    notifyListeners();
  }

  void addRecurringTransaction(RecurringTransaction recurringTransaction) {
    _recurringTransactions.add(recurringTransaction);
    _persistData();
    notifyListeners();
  }

  void removeRecurringTransaction(String id) {
    _recurringTransactions.removeWhere((transaction) => transaction.id == id);
    _persistData();
    notifyListeners();
  }

  double getBudgetUsageForCategory(String categoryId, {DateTime? referenceDate}) {
    final targetDate = referenceDate ?? DateTime.now();
    final relevantBudget = _budgets
        .where((budget) => budget.categoryId == categoryId)
        .where((budget) => _matchesBudgetPeriod(budget, targetDate))
        .fold<Budget?>(null, (current, budget) {
          if (current == null || budget.limit > current.limit) {
            return budget;
          }
          return current;
        });

    if (relevantBudget == null) {
      return 0;
    }

    final spent = _transactions
        .where((transaction) => transaction.categoryId == categoryId)
        .where((transaction) => _matchesBudgetPeriodForTransaction(relevantBudget, transaction.date, targetDate))
        .fold<double>(0, (sum, transaction) => sum + (transaction.type == TransactionType.expense ? transaction.amount : 0));

    return spent;
  }

  double getBudgetTotalForCategory(String categoryId, {DateTime? referenceDate}) {
    final targetDate = referenceDate ?? DateTime.now();
    final relevantBudget = _budgets
        .where((budget) => budget.categoryId == categoryId)
        .where((budget) => _matchesBudgetPeriod(budget, targetDate))
        .fold<Budget?>(null, (current, budget) {
          if (current == null || budget.limit > current.limit) {
            return budget;
          }
          return current;
        });

    return relevantBudget?.limit ?? 0;
  }

  void updateTransaction(FinanceTransaction updatedTransaction) {
    final index = _transactions.indexWhere((transaction) => transaction.id == updatedTransaction.id);
    if (index >= 0) {
      _transactions[index] = updatedTransaction;
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      _persistData();
      notifyListeners();
    }
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((transaction) => transaction.id == id);
    _persistData();
    notifyListeners();
  }

  Map<String, dynamic> toJson() {
    return {
      'settings': _settings.toJson(),
      'accounts': _accounts.map((account) => {'id': account.id, 'name': account.name}).toList(),
      'categories': _categories.map(
        (category) => {
          'id': category.id,
          'name': category.name,
          'type': category.type.name,
        },
      ).toList(),
      'transactions': _transactions.map((transaction) => transaction.toJson()).toList(),
      'budgets': _budgets.map((budget) => budget.toJson()).toList(),
      'recurringTransactions': _recurringTransactions.map((transaction) => transaction.toJson()).toList(),
    };
  }

  void restoreFromJson(Map<String, dynamic> json) {
    if (json['settings'] is Map) {
      _settings = AppSettings.fromJson(Map<String, dynamic>.from(json['settings'] as Map));
    }

    if (json['accounts'] is List) {
      _accounts.clear();
      for (final item in json['accounts'] as List) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          _accounts.add(Account(id: map['id'] as String, name: map['name'] as String));
        }
      }
    }

    if (json['categories'] is List) {
      _categories.clear();
      for (final item in json['categories'] as List) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          _categories.add(
            TransactionCategory(
              id: map['id'] as String,
              name: map['name'] as String,
              type: TransactionType.values.firstWhere(
                (type) => type.name == map['type'],
                orElse: () => TransactionType.expense,
              ),
            ),
          );
        }
      }
    }

    if (json['transactions'] is List) {
      _transactions.clear();
      for (final item in json['transactions'] as List) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final transaction = FinanceTransaction(
            id: map['id'] as String,
            title: map['title'] as String,
            type: TransactionType.values.firstWhere(
              (type) => type.name == map['type'],
              orElse: () => TransactionType.expense,
            ),
            amount: (map['amount'] as num).toDouble(),
            accountId: map['accountId'] as String,
            categoryId: map['categoryId'] as String,
            date: DateTime.parse(map['date'] as String),
            note: map['note'] as String? ?? '',
          );
          _transactions.add(transaction);
        }
      }
    }

    if (json['budgets'] is List) {
      _budgets.clear();
      for (final item in json['budgets'] as List) {
        if (item is Map) {
          _budgets.add(Budget.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    if (json['recurringTransactions'] is List) {
      _recurringTransactions.clear();
      for (final item in json['recurringTransactions'] as List) {
        if (item is Map) {
          _recurringTransactions.add(RecurringTransaction.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    _accounts.removeWhere((account) => account.id == 'bank');
    _categories.removeWhere((category) => category.id == 'freelance');
    _transactions.removeWhere((transaction) => transaction.accountId == 'bank' || transaction.categoryId == 'freelance');

    _transactions.sort((a, b) => b.date.compareTo(a.date));
    _persistData();
    notifyListeners();
  }

  String exportJson() => jsonEncode(toJson());

  bool _matchesBudgetPeriod(Budget budget, DateTime referenceDate) {
    final currentMonth = DateTime(referenceDate.year, referenceDate.month);
    final budgetMonth = DateTime(budget.startDate.year, budget.startDate.month);
    switch (budget.period) {
      case BudgetPeriod.monthly:
        return currentMonth.year == budgetMonth.year && currentMonth.month == budgetMonth.month;
      case BudgetPeriod.quarterly:
        final budgetQuarter = ((budgetMonth.month - 1) ~/ 3);
        final currentQuarter = ((referenceDate.month - 1) ~/ 3);
        return currentQuarter == budgetQuarter && currentMonth.year == budgetMonth.year;
      case BudgetPeriod.yearly:
        return currentMonth.year == budgetMonth.year;
    }
  }

  bool _matchesBudgetPeriodForTransaction(Budget budget, DateTime transactionDate, DateTime referenceDate) {
    switch (budget.period) {
      case BudgetPeriod.monthly:
        return transactionDate.year == referenceDate.year && transactionDate.month == referenceDate.month;
      case BudgetPeriod.quarterly:
        return transactionDate.year == referenceDate.year && ((transactionDate.month - 1) ~/ 3) == ((referenceDate.month - 1) ~/ 3);
      case BudgetPeriod.yearly:
        return transactionDate.year == referenceDate.year;
    }
  }

  Future<void> _persistSettings() async {
    await _persistData();
  }

  Future<void> _persistData() async {
    _persistenceQueue = _persistenceQueue.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('khoraise_data', jsonEncode(toJson()));
    });
    await _persistenceQueue;
  }

  Future<void> _loadPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString('khoraise_data');
      if (savedData != null && savedData.isNotEmpty) {
        restoreFromJson(jsonDecode(savedData) as Map<String, dynamic>);
        return;
      }

      final saved = prefs.getString('khoraise_settings');
      if (saved == null || saved.isEmpty) {
        return;
      }

      final decoded = jsonDecode(saved) as Map<String, dynamic>;
      _settings = AppSettings.fromJson(decoded);
      notifyListeners();
    } on MissingPluginException {
      _settings = const AppSettings();
    } catch (_) {
      _settings = const AppSettings();
    }
  }
}

final financeRepository = FinanceRepository();
