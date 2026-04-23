import 'package:flutter/material.dart';

class HourlyRateDisplay extends StatelessWidget {
  const HourlyRateDisplay({super.key, required this.hourlyRate});

  final double hourlyRate;

  @override
  Widget build(BuildContext context) {
    final formatted = hourlyRate <= 0
        ? '---'
        : '¥${hourlyRate.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('クエスト時間単価（自動計算）',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  )),
          const SizedBox(height: 4),
          Text('$formatted / 時間',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  )),
        ],
      ),
    );
  }
}
