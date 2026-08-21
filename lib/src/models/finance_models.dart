enum TransactionType { income, expense }

enum BudgetPeriod { monthly, quarterly, yearly }

enum RecurringFrequency { daily, weekly, biweekly, monthly, yearly }

class AppSettings {
  const AppSettings({
    this.currencyCode = 'PHP',
    this.currencySymbol = '₱',
    this.compactMode = false,
    this.autoSort = true,
  });

  final String currencyCode;
  final String currencySymbol;
  final bool compactMode;
  final bool autoSort;

  AppSettings copyWith({
    String? currencyCode,
    String? currencySymbol,
    bool? compactMode,
    bool? autoSort,
  }) {
    return AppSettings(
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      compactMode: compactMode ?? this.compactMode,
      autoSort: autoSort ?? this.autoSort,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final savedCode = (json['currencyCode'] ?? 'PHP').toString().toUpperCase();
    final currencyCode = savedCode == 'USD' || savedCode == 'PHP' ? savedCode : 'PHP';
    final currencySymbol = (json['currencySymbol'] ?? _defaultCurrencySymbol(currencyCode)).toString();
    return AppSettings(
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
      compactMode: json['compactMode'] == true,
      autoSort: json['autoSort'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currencyCode': currencyCode,
      'currencySymbol': currencySymbol,
      'compactMode': compactMode,
      'autoSort': autoSort,
    };
  }

  static String _defaultCurrencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'PHP':
        return '₱';
      default:
        return '\$';
    }
  }
}

class Account {
  Account({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

class TransactionCategory {
  TransactionCategory({
    required this.id,
    required this.name,
    required this.type,
  });

  final String id;
  final String name;
  final TransactionType type;
}

class FinanceTransaction {
  FinanceTransaction({
    required this.id,
    required this.title,
    required this.type,
    required this.amount,
    required this.accountId,
    required this.categoryId,
    required this.date,
    required this.note,
  });

  final String id;
  final String title;
  final TransactionType type;
  final double amount;
  final String accountId;
  final String categoryId;
  final DateTime date;
  final String note;

  FinanceTransaction copyWith({
    String? id,
    String? title,
    TransactionType? type,
    double? amount,
    String? accountId,
    String? categoryId,
    DateTime? date,
    String? note,
  }) {
    return FinanceTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'amount': amount,
      'accountId': accountId,
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory FinanceTransaction.fromJson(Map<String, dynamic> json) {
    return FinanceTransaction(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      type: TransactionType.values.firstWhere(
        (type) => type.name == (json['type'] ?? 'expense'),
        orElse: () => TransactionType.expense,
      ),
      amount: (json['amount'] as num? ?? 0).toDouble(),
      accountId: (json['accountId'] ?? '').toString(),
      categoryId: (json['categoryId'] ?? '').toString(),
      date: DateTime.parse((json['date'] ?? DateTime.now().toIso8601String()).toString()),
      note: (json['note'] ?? '').toString(),
    );
  }
}

class Budget {
  Budget({
    required this.id,
    required this.categoryId,
    required this.limit,
    required this.period,
    required this.startDate,
    this.name,
  });

  final String id;
  final String categoryId;
  final double limit;
  final BudgetPeriod period;
  final DateTime startDate;
  final String? name;

  Budget copyWith({
    String? id,
    String? categoryId,
    double? limit,
    BudgetPeriod? period,
    DateTime? startDate,
    String? name,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      limit: limit ?? this.limit,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'limit': limit,
      'period': period.name,
      'startDate': startDate.toIso8601String(),
      'name': name,
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: (json['id'] ?? '').toString(),
      categoryId: (json['categoryId'] ?? '').toString(),
      limit: (json['limit'] as num? ?? 0).toDouble(),
      period: BudgetPeriod.values.firstWhere(
        (period) => period.name == (json['period'] ?? 'monthly'),
        orElse: () => BudgetPeriod.monthly,
      ),
      startDate: DateTime.parse((json['startDate'] ?? DateTime.now().toIso8601String()).toString()),
      name: json['name']?.toString(),
    );
  }
}

class RecurringTransaction {
  RecurringTransaction({
    required this.id,
    required this.title,
    required this.type,
    required this.amount,
    required this.accountId,
    required this.categoryId,
    required this.startDate,
    required this.frequency,
    required this.nextDate,
    required this.note,
  });

  final String id;
  final String title;
  final TransactionType type;
  final double amount;
  final String accountId;
  final String categoryId;
  final DateTime startDate;
  final RecurringFrequency frequency;
  final DateTime nextDate;
  final String note;

  RecurringTransaction copyWith({
    String? id,
    String? title,
    TransactionType? type,
    double? amount,
    String? accountId,
    String? categoryId,
    DateTime? startDate,
    RecurringFrequency? frequency,
    DateTime? nextDate,
    String? note,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      startDate: startDate ?? this.startDate,
      frequency: frequency ?? this.frequency,
      nextDate: nextDate ?? this.nextDate,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'amount': amount,
      'accountId': accountId,
      'categoryId': categoryId,
      'startDate': startDate.toIso8601String(),
      'frequency': frequency.name,
      'nextDate': nextDate.toIso8601String(),
      'note': note,
    };
  }

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      type: TransactionType.values.firstWhere(
        (type) => type.name == (json['type'] ?? 'expense'),
        orElse: () => TransactionType.expense,
      ),
      amount: (json['amount'] as num? ?? 0).toDouble(),
      accountId: (json['accountId'] ?? '').toString(),
      categoryId: (json['categoryId'] ?? '').toString(),
      startDate: DateTime.parse((json['startDate'] ?? DateTime.now().toIso8601String()).toString()),
      frequency: RecurringFrequency.values.firstWhere(
        (frequency) => frequency.name == (json['frequency'] ?? 'monthly'),
        orElse: () => RecurringFrequency.monthly,
      ),
      nextDate: DateTime.parse((json['nextDate'] ?? DateTime.now().toIso8601String()).toString()),
      note: (json['note'] ?? '').toString(),
    );
  }
}
