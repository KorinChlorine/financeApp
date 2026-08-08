// balances.dart
import 'package:flutter/material.dart';

class UserBalance extends StatelessWidget {
  final double income;
  final double expenses;

  const UserBalance({
    super.key,
    required this.income,
    required this.expenses,
  });

  double get balance => income - expenses;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _BalanceItem(label: "Income", value: income, color: color),
        _BalanceItem(label: "Expenses", value: expenses, color: color),
        _BalanceItem(label: "Balance", value: balance, color: color),
      ],
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _BalanceItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}