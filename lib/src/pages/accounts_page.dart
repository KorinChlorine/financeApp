import 'package:flutter/material.dart';
import '../components/date_filter_selector.dart';
import '../components/page_footer.dart';
import '../components/page_header.dart';
import '../models/finance_models.dart';
import '../services/finance_repository.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key, required this.repository});

  final FinanceRepository repository;

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  final _accountController = TextEditingController();
  final _categoryController = TextEditingController();
  TransactionType _selectedType = TransactionType.expense;

  @override
  void dispose() {
    _accountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalIncome = widget.repository.transactions
        .where((transaction) => transaction.type == TransactionType.income)
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
    final totalExpenses = widget.repository.transactions
        .where((transaction) => transaction.type == TransactionType.expense)
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);

    return Scaffold(
      appBar: PageHeader(
        filterMode: DateFilterMode.daily,
        selectedDate: DateTime.now(),
        onFilterChanged: (_) {},
        onDateChanged: (_) {},
        income: totalIncome,
        expenses: totalExpenses,
        showDateSelector: false,
        dateLabel: 'All Accounts',
        showTripleSummary: true,
        leftLabel: 'Income so far',
        rightLabel: 'Expenses so far',
        totalLabel: 'Total in all accounts',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.15)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Accounts', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: widget.repository.accounts.where((account) {
                      final accountTransactions = widget.repository.transactions
                          .where((transaction) => transaction.accountId == account.id)
                          .toList();
                      final accountIncome = accountTransactions
                          .where((transaction) => transaction.type == TransactionType.income)
                          .fold<double>(0, (sum, transaction) => sum + transaction.amount);
                      final accountExpenses = accountTransactions
                          .where((transaction) => transaction.type == TransactionType.expense)
                          .fold<double>(0, (sum, transaction) => sum + transaction.amount);
                      return accountIncome > 0 || accountExpenses > 0;
                    }).map((account) {
                      final accountTransactions = widget.repository.transactions
                          .where((transaction) => transaction.accountId == account.id)
                          .toList();
                      final accountIncome = accountTransactions
                          .where((transaction) => transaction.type == TransactionType.income)
                          .fold<double>(0, (sum, transaction) => sum + transaction.amount);
                      final accountExpenses = accountTransactions
                          .where((transaction) => transaction.type == TransactionType.expense)
                          .fold<double>(0, (sum, transaction) => sum + transaction.amount);
                      final accountTotal = accountIncome - accountExpenses;

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.name,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _AccountDetailTile(
                                    label: 'Income',
                                    value: accountIncome,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _AccountDetailTile(
                                    label: 'Expense',
                                    value: accountExpenses,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _AccountDetailTile(
                                    label: 'Total',
                                    value: accountTotal,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _accountController,
                          decoration: const InputDecoration(labelText: 'New account'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          widget.repository.addAccount(_accountController.text);
                          _accountController.clear();
                          setState(() {});
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.15)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.category_outlined, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Categories', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<TransactionType>(
                    segments: const [
                      ButtonSegment(value: TransactionType.expense, label: Text('Expense')),
                      ButtonSegment(value: TransactionType.income, label: Text('Income')),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (selection) {
                      setState(() => _selectedType = selection.first);
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: widget.repository.categories
                        .where((category) => category.type == _selectedType)
                        .map(
                          (category) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: category.type == TransactionType.expense
                                  ? Colors.red.shade50
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(category.name),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _categoryController,
                          decoration: const InputDecoration(labelText: 'New category'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          widget.repository.addCategory(_selectedType, _categoryController.text);
                          _categoryController.clear();
                          setState(() {});
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const PageFooter(),
    );
  }
}

class _AccountDetailTile extends StatelessWidget {
  const _AccountDetailTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
