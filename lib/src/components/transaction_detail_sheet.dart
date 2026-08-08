import 'package:flutter/material.dart';
import '../models/finance_models.dart';
import '../services/finance_repository.dart';
import 'transaction_form_sheet.dart';

class TransactionDetailSheet extends StatelessWidget {
  const TransactionDetailSheet({
    super.key,
    required this.transaction,
    required this.repository,
  });

  final FinanceTransaction transaction;
  final FinanceRepository repository;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;
    final color = isExpense ? Colors.red.shade700 : Colors.green.shade700;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(transaction.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(
            '${transaction.type.name.toUpperCase()} • ${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Date: ${transaction.date.day}/${transaction.date.month}/${transaction.date.year}'),
          const SizedBox(height: 8),
          Text('Account: ${repository.accounts.firstWhere((account) => account.id == transaction.accountId, orElse: () => repository.accounts.first).name}'),
          const SizedBox(height: 8),
          Text('Category: ${repository.categories.firstWhere((category) => category.id == transaction.categoryId, orElse: () => repository.categories.first).name}'),
          const SizedBox(height: 8),
          Text('Note: ${transaction.note.isEmpty ? 'No note' : transaction.note}'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (sheetContext) => TransactionFormSheet(
                        repository: repository,
                        transaction: transaction,
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    repository.deleteTransaction(transaction.id);
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
