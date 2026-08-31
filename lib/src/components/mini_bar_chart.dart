import 'package:flutter/material.dart';

class MiniBarChart extends StatelessWidget {
  const MiniBarChart({
    super.key,
    required this.values,
    this.labels,
    this.incomeColor = const Color(0xFF4F9D6C),
    this.expenseColor = const Color(0xFFCE6D6D),
    this.backgroundColor = const Color(0xFFE9DCC7),
    this.onBarTap,
  });

  final List<double> values;
  final List<String>? labels;
  final Color incomeColor;
  final Color expenseColor;
  final Color backgroundColor;
  final void Function(int index, double value)? onBarTap;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const SizedBox(height: 120);
    }

    final maxValue = values.map((value) => value.abs()).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.asMap().entries.map((entry) {
          final index = entry.key;
          final value = entry.value;
          final isPositive = value >= 0;
          final normalized = maxValue == 0 ? 0.0 : (value.abs() / maxValue).clamp(0.0, 1.0);

          return Expanded(
            child: GestureDetector(
              onTap: onBarTap == null ? null : () => onBarTap!(index, value),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 20,
                      height: 84 * normalized,
                      decoration: BoxDecoration(
                        color: isPositive ? incomeColor : expenseColor,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                        boxShadow: [
                          BoxShadow(
                            color: (isPositive ? incomeColor : expenseColor).withValues(alpha: 0.22),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      labels != null && index < labels!.length ? labels![index] : '${index + 1}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

Future<void> showGraphDetails(
  BuildContext context, {
  required String title,
  required List<MapEntry<String, String>> rows,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: rows
              .map((row) => ListTile(title: Text(row.key), trailing: Text(row.value)))
              .toList(),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    ),
  );
}
