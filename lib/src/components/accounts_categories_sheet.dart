import 'package:flutter/material.dart';
import '../models/finance_models.dart';
import '../services/finance_repository.dart';

class AccountsCategoriesSheet extends StatefulWidget {
  const AccountsCategoriesSheet({super.key, required this.repository});

  final FinanceRepository repository;

  @override
  State<AccountsCategoriesSheet> createState() => _AccountsCategoriesSheetState();
}

class _AccountsCategoriesSheetState extends State<AccountsCategoriesSheet> {
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Accounts & Categories', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('Accounts', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: widget.repository.accounts
                  .map(
                    (account) => Chip(label: Text(account.name)),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 20),
            Text('Categories', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
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
              spacing: 8,
              children: widget.repository.categories
                  .where((category) => category.type == _selectedType)
                  .map((category) => Chip(label: Text(category.name)))
                  .toList(),
            ),
            const SizedBox(height: 12),
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
    );
  }
}
