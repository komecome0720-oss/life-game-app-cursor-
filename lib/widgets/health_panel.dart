import 'package:flutter/material.dart';
import 'package:task_manager/models/health_scores.dart';
import 'package:task_manager/widgets/segmented_progress_bar.dart';

class HealthPanel extends StatelessWidget {
  const HealthPanel({super.key, required this.scores});

  final HealthScores scores;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('健康管理', style: text.labelMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 6),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _row(context, '食事', scores.meal),
                    _row(context, '睡眠', scores.sleep),
                    _row(context, '運動', scores.exercise),
                    _row(context, '瞑想', scores.meditation),
                    const Divider(height: 12),
                    _totalRow(context, scores.total),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, int score) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: text.bodySmall)),
              Text('$score', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 4),
          SegmentedProgressBar(score: score),
        ],
      ),
    );
  }

  Widget _totalRow(BuildContext context, int total) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('合計', style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
            Text('$total', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
          ],
        ),
        const SizedBox(height: 4),
        TotalSegmentedProgressBar(totalScore: total),
      ],
    );
  }
}
