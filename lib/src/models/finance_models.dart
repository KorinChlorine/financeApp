enum TransactionType { income, expense }

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
}
