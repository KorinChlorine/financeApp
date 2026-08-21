import 'package:flutter/material.dart';
import '../components/app_drawer.dart';
import '../components/date_filter_selector.dart';
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

  Future<void> _addScheduledPayment() async {
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => _ScheduledPaymentDialog(repository: widget.repository),
    );
    if (added == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalIncome = widget.repository.transactions
        .where((transaction) => transaction.type == TransactionType.income)
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
    final totalExpenses = widget.repository.transactions
        .where((transaction) => transaction.type == TransactionType.expense)
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);

    final accountStats = widget.repository.accounts.map((account) {
      final accountTransactions = widget.repository.transactions
          .where((transaction) => transaction.accountId == account.id)
          .toList();
      final accountIncome = accountTransactions
          .where((transaction) => transaction.type == TransactionType.income)
          .fold<double>(0, (sum, transaction) => sum + transaction.amount);
      final accountExpenses = accountTransactions
          .where((transaction) => transaction.type == TransactionType.expense)
          .fold<double>(0, (sum, transaction) => sum + transaction.amount);
      return {
        'account': account,
        'total': accountIncome - accountExpenses,
        'income': accountIncome,
        'expense': accountExpenses,
      };
    }).toList();

    final activeAccounts = accountStats.where((entry) => (entry['total'] as double) != 0).length;
    final highestAccount = accountStats.isEmpty
        ? null
        : accountStats.reduce((a, b) => (a['total'] as double) > (b['total'] as double) ? a : b);
    final maxAccountValue = accountStats.isEmpty
        ? 1.0
        : accountStats.map((entry) => (entry['total'] as double).abs()).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/accounts'),
      appBar: PageHeader(
        filterMode: DateFilterMode.daily,
        selectedDate: DateTime.now(),
        onFilterChanged: (_) {},
        onDateChanged: (_) {},
        income: totalIncome,
        expenses: totalExpenses,
        showDateSelector: false,
        showSearch: false,
        dateLabel: 'All Accounts',
        showTripleSummary: true,
        topPadding: 90,
        leftLabel: 'Income so far',
        rightLabel: 'Expenses so far',
        totalLabel: 'Total in all accounts',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)),
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
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          label: 'Total balance',
                          value: accountStats.fold<double>(0, (sum, entry) => sum + (entry['total'] as double)),
                          icon: Icons.account_balance_wallet_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricCard(
                          label: 'Active accounts',
                          value: activeAccounts.toDouble(),
                          icon: Icons.pie_chart_rounded,
                          color: Colors.green.shade700,
                          isCount: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricCard(
                          label: 'Top account',
                          value: highestAccount == null ? 0 : (highestAccount['total'] as double),
                          icon: Icons.trending_up_rounded,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Balance flow',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 11),
                        SizedBox(
                          height: 85,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: accountStats.isEmpty
                                ? [
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          'No account activity yet',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ),
                                    ),
                                  ]
                                : accountStats.map((entry) {
                                    final account = entry['account'] as Account;
                                    final total = (entry['total'] as double).abs();
                                    final height = total == 0 ? 10.0 : (total / maxAccountValue) * 60;
                                    final isPositive = (entry['total'] as double) >= 0;
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Container(
                                              height: height.clamp(18.0, 70.0),
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: isPositive
                                                      ? [Colors.green.shade400, Colors.green.shade700]
                                                      : [Colors.red.shade400, Colors.red.shade700],
                                                ),
                                                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              account.name.length > 6 ? account.name.substring(0, 6) : account.name,
                                              style: Theme.of(context).textTheme.labelSmall,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Column(
                    children: widget.repository.accounts.map((account) {
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
                      final totalFlow = (accountIncome + accountExpenses).clamp(1.0, double.infinity);

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    account.name,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (dialogContext) => AlertDialog(
                                        title: const Text('Delete account'),
                                        content: Text(
                                          'Delete “${account.name}”? This will also remove its transactions.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(dialogContext).pop(),
                                            child: const Text('Cancel'),
                                          ),
                                          FilledButton(
                                            onPressed: () {
                                              widget.repository.removeAccount(account.id);
                                              Navigator.of(dialogContext).pop();
                                              setState(() {});
                                            },
                                            style: FilledButton.styleFrom(
                                              backgroundColor: Colors.red.shade700,
                                            ),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.delete_outline_rounded),
                                  tooltip: 'Delete account',
                                  color: Colors.red.shade700,
                                  iconSize: 24,
                                  constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                                  padding: const EdgeInsets.all(8),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: accountTotal >= 0
                                        ? Colors.green.shade100
                                        : Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    accountTotal >= 0 ? 'Healthy' : 'Watch list',
                                    style: TextStyle(
                                      color: accountTotal >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: (accountIncome / totalFlow).clamp(0.05, 1.0),
                                minHeight: 8,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  accountTotal >= 0 ? Colors.green.shade500 : Colors.red.shade500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
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
              side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event_repeat_outlined, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Scheduled payments', style: Theme.of(context).textTheme.titleMedium)),
                      FilledButton.icon(
                        onPressed: _addScheduledPayment,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (widget.repository.recurringTransactions.isEmpty)
                    const Text('Add rent, bills, debts, or other payments you need to remember.')
                  else
                    Column(
                      children: widget.repository.recurringTransactions.map((payment) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.payments_outlined, color: Colors.orange.shade700),
                          title: Text(payment.title),
                          subtitle: Text('Next: ${payment.nextDate.day}/${payment.nextDate.month}/${payment.nextDate.year} · ${payment.frequency.name}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(widget.repository.formatCurrency(payment.amount), style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w700)),
                              IconButton(
                                onPressed: () {
                                  widget.repository.removeRecurringTransaction(payment.id);
                                  setState(() {});
                                },
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Delete payment',
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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
              side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)),
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
                  Column(
                    children: widget.repository.categories
                        .where((category) => category.type == _selectedType)
                        .map((category) {
                          final budget = widget.repository.budgets
                              .where((item) => item.categoryId == category.id)
                              .fold<Budget?>(null, (current, item) {
                                if (current == null || item.limit > current.limit) {
                                  return item;
                                }
                                return current;
                              });
                          final spent = widget.repository.getBudgetUsageForCategory(category.id);
                          final limit = widget.repository.getBudgetTotalForCategory(category.id);

                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: category.type == TransactionType.expense
                                  ? Colors.red.shade50
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        category.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (budget != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Text(
                                            '${spent.toStringAsFixed(0)} / ${limit.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              color: spent > limit ? Colors.red.shade700 : Colors.green.shade700,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (category.type == TransactionType.expense)
                                  IconButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (dialogContext) => _CategoryBudgetDialog(
                                          category: category,
                                          repository: widget.repository,
                                        ),
                                      ).then((_) {
                                        if (mounted) {
                                          setState(() {});
                                        }
                                      });
                                    },
                                    tooltip: 'Set budget',
                                    icon: Icon(
                                      Icons.tune_rounded,
                                      size: 24,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    iconSize: 24,
                                    constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                                    padding: const EdgeInsets.all(8),
                                  ),
                                IconButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (dialogContext) => AlertDialog(
                                        title: const Text('Delete category'),
                                        content: Text('Delete “${category.name}”? This will remove related transactions and budgets.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(dialogContext).pop(),
                                            child: const Text('Cancel'),
                                          ),
                                          FilledButton(
                                            onPressed: () {
                                              widget.repository.removeCategory(category.id);
                                              Navigator.of(dialogContext).pop();
                                              setState(() {});
                                            },
                                            style: FilledButton.styleFrom(
                                              backgroundColor: Colors.red.shade700,
                                            ),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  tooltip: 'Delete category',
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 24,
                                    color: Colors.red.shade700,
                                  ),
                                  iconSize: 24,
                                  constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                                  padding: const EdgeInsets.all(8),
                                ),
                              ],
                            ),
                          );
                        })
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
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isCount = false,
  });

  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final bool isCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isCount ? value.toStringAsFixed(0) : value.toStringAsFixed(2),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBudgetDialog extends StatefulWidget {
  const _CategoryBudgetDialog({
    required this.category,
    required this.repository,
  });

  final TransactionCategory category;
  final FinanceRepository repository;

  @override
  State<_CategoryBudgetDialog> createState() => _CategoryBudgetDialogState();
}

class _CategoryBudgetDialogState extends State<_CategoryBudgetDialog> {
  late final TextEditingController _limitController;
  BudgetPeriod _period = BudgetPeriod.monthly;

  @override
  void initState() {
    super.initState();
    final existing = widget.repository.budgets
        .where((budget) => budget.categoryId == widget.category.id)
        .fold<Budget?>(null, (current, budget) {
          if (current == null || budget.limit > current.limit) {
            return budget;
          }
          return current;
        });

    _limitController = TextEditingController(text: existing == null ? '' : existing.limit.toStringAsFixed(0));
    _period = existing?.period ?? BudgetPeriod.monthly;
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Budget for ${widget.category.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _limitController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Budget limit'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<BudgetPeriod>(
            initialValue: _period,
            decoration: const InputDecoration(labelText: 'Period'),
            items: const [
              DropdownMenuItem(value: BudgetPeriod.monthly, child: Text('Monthly')),
              DropdownMenuItem(value: BudgetPeriod.quarterly, child: Text('Quarterly')),
              DropdownMenuItem(value: BudgetPeriod.yearly, child: Text('Yearly')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _period = value);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final limit = double.tryParse(_limitController.text.trim());
            if (limit != null && limit > 0) {
              widget.repository.addBudgetForCategory(
                widget.category.id,
                limit,
                _period,
                DateTime.now(),
              );
            }
            Navigator.of(context).pop();
            if (mounted) {
              setState(() {});
            }
          },
          child: const Text('Save'),
        ),
      ],
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

class _ScheduledPaymentDialog extends StatefulWidget {
  const _ScheduledPaymentDialog({required this.repository});

  final FinanceRepository repository;

  @override
  State<_ScheduledPaymentDialog> createState() => _ScheduledPaymentDialogState();
}

class _ScheduledPaymentDialogState extends State<_ScheduledPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late String _accountId;
  late String _categoryId;
  late DateTime _nextDate;
  RecurringFrequency _frequency = RecurringFrequency.monthly;

  @override
  void initState() {
    super.initState();
    _accountId = widget.repository.accounts.first.id;
    _categoryId = widget.repository.categories.firstWhere((category) => category.type == TransactionType.expense).id;
    _nextDate = DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add scheduled payment'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Payment name'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Enter a payment name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Amount (${widget.repository.currencyCode})'),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  return amount == null || amount <= 0 ? 'Enter a valid amount' : null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _accountId,
                decoration: const InputDecoration(labelText: 'Account'),
                items: widget.repository.accounts.map((account) => DropdownMenuItem(value: account.id, child: Text(account.name))).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _accountId = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: widget.repository.categories
                    .where((category) => category.type == TransactionType.expense)
                    .map((category) => DropdownMenuItem(value: category.id, child: Text(category.name)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _categoryId = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<RecurringFrequency>(
                initialValue: _frequency,
                decoration: const InputDecoration(labelText: 'Repeats'),
                items: RecurringFrequency.values
                    .map((frequency) => DropdownMenuItem(value: frequency, child: Text(frequency.name)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _frequency = value);
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _nextDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _nextDate = picked);
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text('Next payment: ${_nextDate.day}/${_nextDate.month}/${_nextDate.year}'),
                ),
              ),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Add payment')),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.repository.addRecurringTransaction(
      RecurringTransaction(
        id: 'recurring_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        type: TransactionType.expense,
        amount: double.parse(_amountController.text.trim()),
        accountId: _accountId,
        categoryId: _categoryId,
        startDate: _nextDate,
        frequency: _frequency,
        nextDate: _nextDate,
        note: _noteController.text.trim(),
      ),
    );
    Navigator.of(context).pop(true);
  }
}
