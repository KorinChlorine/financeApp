// balances.dart
import 'package:flutter/material.dart';

class UserBalance extends StatelessWidget {
  final double income;
  final double expenses;
  final String currencySymbol;

  const UserBalance({
    super.key,
    required this.income,
    required this.expenses,
    this.currencySymbol = '\$',
  });

  double get balance => income - expenses;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFE9DFD4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF765F4E).withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BalanceItem(label: 'Income', value: income, color: const Color(0xFF4F9D6C), currencySymbol: currencySymbol),
          _BalanceItem(label: 'Expenses', value: expenses, color: const Color(0xFFCE6D6D), currencySymbol: currencySymbol),
          _BalanceItem(label: 'Balance', value: balance, color: const Color(0xFF3B7A56), currencySymbol: currencySymbol),
        ],
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String currencySymbol;

  const _BalanceItem({
    required this.label,
    required this.value,
    required this.color,
    required this.currencySymbol,
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
          '$currencySymbol${value.toStringAsFixed(2)}',
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