import 'package:flutter/material.dart';
import '../models/finance_models.dart';
import '../services/finance_repository.dart';

class TransactionFormSheet extends StatefulWidget {
  const TransactionFormSheet({
    super.key,
    required this.repository,
    this.transaction,
    this.initialDate,
  });

  final FinanceRepository repository;
  final FinanceTransaction? transaction;
  final DateTime? initialDate;

  @override
  State<TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends State<TransactionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late TransactionType _type;
  late String _accountId;
  late String _categoryId;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    _type = transaction?.type ?? TransactionType.expense;
    _accountId = transaction?.accountId ?? widget.repository.accounts.first.id;
    _categoryId = transaction?.categoryId ?? _defaultCategoryIdFor(_type);
    _selectedDate = transaction?.date ?? widget.initialDate ?? DateTime.now();
    _titleController.text = transaction?.title ?? '';
    _amountController.text = transaction?.amount.toString() ?? '';
    _noteController.text = transaction?.note ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _defaultCategoryIdFor(TransactionType type) {
    return widget.repository.categories
        .where((category) => category.type == type)
        .first
        .id;
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.repository.categories.where((category) => category.type == _type).toList();
    final selectedCategoryId = categories.any((category) => category.id == _categoryId)
        ? _categoryId
        : (categories.isNotEmpty ? categories.first.id : '');

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.transaction == null ? 'Add transaction' : 'Edit transaction',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(value: TransactionType.expense, label: Text('Expense')),
                  ButtonSegment(value: TransactionType.income, label: Text('Income')),
                ],
                selected: {_type},
                onSelectionChanged: (selection) {
                  setState(() {
                    _type = selection.first;
                    _categoryId = _defaultCategoryIdFor(_type);
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter an amount';
                  }
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _accountId,
                decoration: const InputDecoration(labelText: 'Account'),
                items: widget.repository.accounts
                    .map(
                      (account) => DropdownMenuItem(
                        value: account.id,
                        child: Text(account.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _accountId = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategoryId.isEmpty ? null : selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _categoryId = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() => _selectedDate = pickedDate);
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final transaction = FinanceTransaction(
      id: widget.transaction?.id ?? 'tx_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      type: _type,
      amount: double.parse(_amountController.text.trim()),
      accountId: _accountId,
      categoryId: _categoryId,
      date: _selectedDate,
      note: _noteController.text.trim(),
    );

    if (widget.transaction == null) {
      widget.repository.addTransaction(transaction);
    } else {
      widget.repository.updateTransaction(transaction);
    }

    Navigator.of(context).pop();
  }
}
