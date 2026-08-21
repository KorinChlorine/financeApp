import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';

import '../components/app_drawer.dart';
import '../components/date_filter_selector.dart';
import '../models/finance_models.dart';
import '../components/page_header.dart';
import '../services/file_storage_service.dart';
import '../services/finance_repository.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.repository});

  final FinanceRepository repository;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _storage = FileStorageService();
  final _currencies = ['PHP', 'USD'];
  late String _selectedCurrency;
  late bool _compactMode;
  late bool _autoSort;
  bool _reportBusy = false;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.repository.currencyCode;
    _compactMode = widget.repository.settings.compactMode;
    _autoSort = widget.repository.settings.autoSort;
  }

  Future<void> _saveSettings() async {
    final settings = AppSettings(
      currencyCode: _selectedCurrency,
      currencySymbol: _currencySymbolFor(_selectedCurrency),
      compactMode: _compactMode,
      autoSort: _autoSort,
    );
    widget.repository.updateSettings(settings);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('khoraise_settings', jsonEncode(settings.toJson()));
  }

  String _currencySymbolFor(String code) {
    switch (code) {
      case 'PHP':
        return '₱';
      default:
        return '\$';
    }
  }

  Future<void> _exportData() async {
    final path = await _storage.exportJson(widget.repository.exportJson());
    if (!mounted) return;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export cancelled.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported to $path')),
    );
  }

  Future<void> _importData() async {
    final imported = await _storage.importJson();
    if (!mounted) return;
    if (imported == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Import cancelled or invalid file.')),
      );
      return;
    }

    widget.repository.restoreFromJson(imported);
    setState(() {
      _selectedCurrency = widget.repository.currencyCode;
      _compactMode = widget.repository.settings.compactMode;
      _autoSort = widget.repository.settings.autoSort;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data imported successfully.')),
    );
  }

  Future<void> _savePdfReport() async {
    if (_reportBusy) return;
    setState(() => _reportBusy = true);
    try {
      final document = pw.Document();
      final currency = widget.repository.currencyCode;
      final transactions = widget.repository.transactions;
      final income = widget.repository.totalIncome;
      final expenses = widget.repository.totalExpenses;
      final balances = widget.repository.accounts.map((account) {
        final balance = transactions.where((transaction) => transaction.accountId == account.id).fold<double>(
              0,
              (sum, transaction) => sum + (transaction.type == TransactionType.income ? transaction.amount : -transaction.amount),
            );
        return [account.name, _reportAmount(currency, balance)];
      }).toList();
      final budgets = widget.repository.budgets.map((budget) {
        final category = widget.repository.categories.where((item) => item.id == budget.categoryId).firstOrNull;
        final spent = widget.repository.getBudgetUsageForCategory(budget.categoryId);
        return [category?.name ?? 'Category', _reportAmount(currency, spent), _reportAmount(currency, budget.limit)];
      }).toList();
      final scheduled = widget.repository.recurringTransactions.map((payment) {
        return [payment.title, _reportAmount(currency, payment.amount), '${payment.nextDate.day}/${payment.nextDate.month}/${payment.nextDate.year}', payment.frequency.name];
      }).toList();
      final recentTransactions = transactions.take(20).map((transaction) {
        return [
          '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
          transaction.title,
          transaction.type.name,
          _reportAmount(currency, transaction.amount),
        ];
      }).toList();

      document.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Header(level: 0, text: 'Khoraise financial report'),
            pw.Text('Generated ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: const ['Summary', 'Amount'],
              data: [
                ['Income', _reportAmount(currency, income)],
                ['Expenses', _reportAmount(currency, expenses)],
                ['Balance', _reportAmount(currency, income - expenses)],
              ],
            ),
            pw.SizedBox(height: 18),
            pw.Header(level: 1, text: 'Account balances'),
            _reportTable(['Account', 'Balance'], balances),
            if (budgets.isNotEmpty) ...[
              pw.SizedBox(height: 18),
              pw.Header(level: 1, text: 'Budget progress'),
              _reportTable(['Category', 'Spent', 'Limit'], budgets),
            ],
            if (scheduled.isNotEmpty) ...[
              pw.SizedBox(height: 18),
              pw.Header(level: 1, text: 'Scheduled payments'),
              _reportTable(['Payment', 'Amount', 'Next date', 'Frequency'], scheduled),
            ],
            if (recentTransactions.isNotEmpty) ...[
              pw.SizedBox(height: 18),
              pw.Header(level: 1, text: 'Recent transactions'),
              _reportTable(['Date', 'Title', 'Type', 'Amount'], recentTransactions),
            ],
          ],
        ),
      );

      final path = await _storage.exportPdf(await document.save());
      if (!mounted) return;
      if (path == null) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF report saved to $path.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save the PDF report.')),
        );
      }
    } finally {
      if (mounted) setState(() => _reportBusy = false);
    }
  }

  pw.Widget _reportTable(List<String> headers, List<List<String>> rows) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellPadding: const pw.EdgeInsets.all(5),
    );
  }

  String _reportAmount(String currency, double amount) => '$currency ${amount.toStringAsFixed(2)}';

  Future<void> _resetApp() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset app?'),
        content: const Text('This will permanently delete your transactions, budgets, and recurring transactions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Reset app'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await widget.repository.resetApp();
    if (!mounted) return;
    setState(() {
      _selectedCurrency = widget.repository.currencyCode;
      _compactMode = widget.repository.settings.compactMode;
      _autoSort = widget.repository.settings.autoSort;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('App reset successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/settings'),
      appBar: PageHeader(
        filterMode: DateFilterMode.monthly,
        selectedDate: DateTime.now(),
        onFilterChanged: (_) {},
        onDateChanged: (_) {},
        income: widget.repository.totalIncome,
        expenses: widget.repository.totalExpenses,
        showDateSelector: false,
        showSearch: true,
        showBalance: false,
        dateLabel: 'Settings',
        showTripleSummary: false,
        headerHeight: 145,
        toolbarHeight: 70,
        topPadding: 75,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('General', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCurrency,
                    decoration: const InputDecoration(labelText: 'Currency'),
                    items: _currencies
                        .map((code) => DropdownMenuItem(value: code, child: Text(code)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedCurrency = value);
                      _saveSettings();
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: _compactMode,
                    title: const Text('Compact mode'),
                    subtitle: const Text('Tighter cards for a denser dashboard.'),
                    onChanged: (value) {
                      setState(() => _compactMode = value);
                      _saveSettings();
                    },
                  ),
                  SwitchListTile(
                    value: _autoSort,
                    title: const Text('Auto sort transactions'),
                    subtitle: const Text('New transactions appear at the top.'),
                    onChanged: (value) {
                      setState(() => _autoSort = value);
                      _saveSettings();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Data backup', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _exportData,
                      icon: const Icon(Icons.file_upload_outlined),
                      label: const Text('Export data'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _reportBusy ? null : _savePdfReport,
                      icon: _reportBusy
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(_reportBusy ? 'Saving report...' : 'Create PDF report'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _importData,
                      icon: const Icon(Icons.file_download_outlined),
                      label: const Text('Import data'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _resetApp,
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('Reset app'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                      ),
                    ),
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
