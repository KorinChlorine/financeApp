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
                decoration: const InputDecoration(labelText: 'Title (optional)'),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
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
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _openAmountCalculator,
                    icon: const Icon(Icons.calculate_outlined),
                    tooltip: 'Open calculator',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _accountId,
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
                initialValue: selectedCategoryId.isEmpty ? null : selectedCategoryId,
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

  Future<void> _openAmountCalculator() async {
    final result = await showDialog<double>(
      context: context,
      builder: (_) => _AmountCalculatorDialog(initialValue: _amountController.text),
    );
    if (result != null && mounted) {
      _amountController.text = result.toStringAsFixed(2);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final navigator = Navigator.of(context);
    final amount = double.parse(_amountController.text.trim());
    final category = widget.repository.categories.firstWhere(
      (item) => item.id == _categoryId,
      orElse: () => TransactionCategory(
        id: '',
        name: 'Category',
        type: TransactionType.expense,
      ),
    );

    if (_type == TransactionType.expense && category.type == TransactionType.expense) {
      final currentSpent = widget.repository.getBudgetUsageForCategory(_categoryId);
      final budgetLimit = widget.repository.getBudgetTotalForCategory(_categoryId);
      if (budgetLimit > 0 && currentSpent + amount > budgetLimit) {
        final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Expanded(child: Text('Budget exceeded')),
              ],
            ),
            content: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This expense would push “${category.name}” over its budget limit.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  _BudgetWarningRow(
                    label: 'Spent',
                    value: widget.repository.formatCurrency(currentSpent),
                  ),
                  const SizedBox(height: 6),
                  _BudgetWarningRow(
                    label: 'Limit',
                    value: widget.repository.formatCurrency(budgetLimit),
                  ),
                  const SizedBox(height: 6),
                  _BudgetWarningRow(
                    label: 'After this',
                    value: widget.repository.formatCurrency(currentSpent + amount),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Save anyway'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                ),
              ),
            ],
          ),
        );

        if (shouldContinue != true) {
          return;
        }
      }
    }

    final transaction = FinanceTransaction(
      id: widget.transaction?.id ?? 'tx_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      type: _type,
      amount: amount,
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

    if (mounted) {
      navigator.pop();
    }
  }
}

class _BudgetWarningRow extends StatelessWidget {
  const _BudgetWarningRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.orange.shade800,
          ),
        ),
      ],
    );
  }
}

class _AmountCalculatorDialog extends StatefulWidget {
  const _AmountCalculatorDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_AmountCalculatorDialog> createState() => _AmountCalculatorDialogState();
}

class _AmountCalculatorDialogState extends State<_AmountCalculatorDialog> {
  late String _expression;

  @override
  void initState() {
    super.initState();
    _expression = widget.initialValue;
  }

  void _append(String value) {
    setState(() => _expression += value);
  }

  void _clear() {
    setState(() => _expression = '');
  }

  void _backspace() {
    if (_expression.isEmpty) return;
    setState(() => _expression = _expression.substring(0, _expression.length - 1));
  }

  void _useResult() {
    final result = _evaluate(_expression);
    if (result == null || result <= 0) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final result = _evaluate(_expression);
    return AlertDialog(
      title: const Text('Amount calculator'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_expression.isEmpty ? '0' : _expression, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 4),
                  Text(
                    result == null ? ' ' : '= ${result.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.35,
              children: [
                _key('7'), _key('8'), _key('9'), _key('/'),
                _key('4'), _key('5'), _key('6'), _key('*'),
                _key('1'), _key('2'), _key('3'), _key('-'),
                _key('0'), _key('.'), _key('+'), _key('C', onPressed: _clear),
              ],
            ),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: _backspace, child: const Icon(Icons.backspace_outlined))),
                const SizedBox(width: 8),
                Expanded(child: FilledButton(onPressed: result == null ? null : _useResult, child: const Text('Use amount'))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _key(String label, {VoidCallback? onPressed}) {
    return FilledButton.tonal(
      onPressed: onPressed ?? () => _append(label),
      child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
    );
  }

  double? _evaluate(String expression) {
    try {
      final parser = _ExpressionParser(expression);
      final value = parser.parse();
      return parser.isAtEnd && value.isFinite ? value : null;
    } catch (_) {
      return null;
    }
  }
}

class _ExpressionParser {
  _ExpressionParser(this.expression);

  final String expression;
  int _index = 0;

  bool get isAtEnd {
    _skipSpaces();
    return _index == expression.length;
  }

  double parse() => _parseAdditive();

  double _parseAdditive() {
    var value = _parseMultiplicative();
    while (true) {
      _skipSpaces();
      if (_match('+')) {
        value += _parseMultiplicative();
      } else if (_match('-')) {
        value -= _parseMultiplicative();
      } else {
        return value;
      }
    }
  }

  double _parseMultiplicative() {
    var value = _parseNumber();
    while (true) {
      _skipSpaces();
      if (_match('*')) {
        value *= _parseNumber();
      } else if (_match('/')) {
        final divisor = _parseNumber();
        if (divisor == 0) throw const FormatException();
        value /= divisor;
      } else {
        return value;
      }
    }
  }

  double _parseNumber() {
    _skipSpaces();
    final start = _index;
    if (_match('-')) return -_parseNumber();
    while (_index < expression.length && '0123456789.'.contains(expression[_index])) {
      _index++;
    }
    if (start == _index) throw const FormatException();
    final value = double.tryParse(expression.substring(start, _index));
    if (value == null) throw const FormatException();
    return value;
  }

  bool _match(String character) {
    if (_index < expression.length && expression[_index] == character) {
      _index++;
      return true;
    }
    return false;
  }

  void _skipSpaces() {
    while (_index < expression.length && expression[_index].trim().isEmpty) {
      _index++;
    }
  }
}
