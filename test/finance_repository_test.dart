import 'package:flutter_test/flutter_test.dart';
import 'package:finance_management_app/src/components/date_filter_selector.dart';
import 'package:finance_management_app/src/models/finance_models.dart';
import 'package:finance_management_app/src/pages/analysis.dart';
import 'package:finance_management_app/src/services/finance_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('FinanceRepository', () {
    test('starts with realistic demo data so the app feels complete out of the box', () {
      final repository = FinanceRepository();

      expect(repository.accounts, isNotEmpty);
      expect(repository.categories, isNotEmpty);
      expect(repository.transactions, isNotEmpty);
      expect(repository.totalIncome, greaterThan(0));
      expect(repository.totalExpenses, greaterThan(0));
      expect(repository.balance, isNotNull);
    });

    test('keeps expense and income totals in sync with transactions', () {
      final repository = FinanceRepository();
      final originalIncome = repository.totalIncome;

      repository.addTransaction(
        FinanceTransaction(
          id: 'test-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Extra income',
          type: TransactionType.income,
          amount: 250,
          accountId: repository.accounts.first.id,
          categoryId: repository.categories
              .firstWhere((category) => category.type == TransactionType.income)
              .id,
          date: DateTime.now(),
          note: 'Test',
        ),
      );

      expect(repository.totalIncome, equals(originalIncome + 250));
      expect(repository.balance, equals(repository.totalIncome - repository.totalExpenses));
      expect(repository.transactions, isNotEmpty);
    });

    test('supports monthly budgets and recurring transactions', () {
      final repository = FinanceRepository();
      final expenseCategory = repository.categories
          .firstWhere((category) => category.type == TransactionType.expense);

      repository.addBudget(
        Budget(
          id: 'budget-${DateTime.now().millisecondsSinceEpoch}',
          categoryId: expenseCategory.id,
          limit: 600,
          period: BudgetPeriod.monthly,
          startDate: DateTime.now(),
        ),
      );

      repository.addRecurringTransaction(
        RecurringTransaction(
          id: 'recurring-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Weekly groceries',
          type: TransactionType.expense,
          amount: 85,
          accountId: repository.accounts.first.id,
          categoryId: expenseCategory.id,
          startDate: DateTime.now(),
          frequency: RecurringFrequency.weekly,
          nextDate: DateTime.now().add(const Duration(days: 7)),
          note: 'Regular shop',
        ),
      );

      expect(repository.budgets, isNotEmpty);
      expect(repository.recurringTransactions, isNotEmpty);
      expect(repository.budgets.first.limit, equals(600));
      expect(repository.recurringTransactions.first.frequency, equals(RecurringFrequency.weekly));
    });

    test('analysis chart values change with the selected date filter', () {
      final baseDate = DateTime(2026, 8, 21);
      final repository = FinanceRepository();

      final incomeCategory = repository.categories
          .firstWhere((category) => category.type == TransactionType.income);
      final expenseCategory = repository.categories
          .firstWhere((category) => category.type == TransactionType.expense);

      repository.addTransaction(
        FinanceTransaction(
          id: 'day-income',
          title: 'Day income',
          type: TransactionType.income,
          amount: 100,
          accountId: repository.accounts.first.id,
          categoryId: incomeCategory.id,
          date: baseDate,
          note: 'Daily',
        ),
      );
      repository.addTransaction(
        FinanceTransaction(
          id: 'week-income',
          title: 'Week income',
          type: TransactionType.income,
          amount: 200,
          accountId: repository.accounts.first.id,
          categoryId: incomeCategory.id,
          date: baseDate.add(const Duration(days: 7)),
          note: 'Weekly',
        ),
      );
      repository.addTransaction(
        FinanceTransaction(
          id: 'month-income',
          title: 'Month income',
          type: TransactionType.income,
          amount: 300,
          accountId: repository.accounts.first.id,
          categoryId: incomeCategory.id,
          date: DateTime(baseDate.year, baseDate.month + 1, 1),
          note: 'Monthly',
        ),
      );
      repository.addTransaction(
        FinanceTransaction(
          id: 'year-income',
          title: 'Year income',
          type: TransactionType.income,
          amount: 400,
          accountId: repository.accounts.first.id,
          categoryId: incomeCategory.id,
          date: DateTime(baseDate.year + 1, 1, 1),
          note: 'Yearly',
        ),
      );
      repository.addTransaction(
        FinanceTransaction(
          id: 'day-expense',
          title: 'Day expense',
          type: TransactionType.expense,
          amount: 50,
          accountId: repository.accounts.first.id,
          categoryId: expenseCategory.id,
          date: baseDate,
          note: 'Daily',
        ),
      );

      final dailyValues = buildAnalysisChartValues(
        transactions: repository.transactions,
        filterMode: DateFilterMode.daily,
        selectedDate: baseDate,
      );
      final weeklyValues = buildAnalysisChartValues(
        transactions: repository.transactions,
        filterMode: DateFilterMode.weekly,
        selectedDate: baseDate,
      );
      final monthlyValues = buildAnalysisChartValues(
        transactions: repository.transactions,
        filterMode: DateFilterMode.monthly,
        selectedDate: baseDate,
      );
      final yearlyValues = buildAnalysisChartValues(
        transactions: repository.transactions,
        filterMode: DateFilterMode.yearly,
        selectedDate: baseDate,
      );

      expect(dailyValues.length, equals(7));
      expect(weeklyValues.length, equals(7));
      expect(monthlyValues.length, equals(6));
      expect(yearlyValues.length, equals(7));
      expect(dailyValues.any((value) => value != 0), isTrue);
      expect(weeklyValues.any((value) => value != 0), isTrue);
      expect(monthlyValues.any((value) => value != 0), isTrue);
      expect(yearlyValues.any((value) => value != 0), isTrue);
    });
  });
}
