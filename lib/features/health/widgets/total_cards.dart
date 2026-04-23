import 'package:flutter/material.dart';
import 'package:task_manager/features/health/model/health_log.dart';

/// 合計点数カード（100点満点）
class TotalScoreCard extends StatelessWidget {
  const TotalScoreCard({super.key, required this.log});
  final HealthLog log;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Text('合計点数', style: text.labelMedium),
              ],
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: text.bodyMedium,
                children: [
                  TextSpan(
                    text: '${log.totalScore}',
                    style: text.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                  const TextSpan(text: ' / 100'),
                ],
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (log.totalScore / 100).clamp(0, 1),
                minHeight: 6,
                backgroundColor: scheme.surfaceContainerHighest,
                color: scheme.tertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 合計金額カード（「?」ヘルプ付き）
class TotalEarningsCard extends StatelessWidget {
  const TotalEarningsCard({
    super.key,
    required this.log,
    required this.onHelpTap,
  });

  final HealthLog log;
  final VoidCallback onHelpTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.savings_outlined, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Text('獲得金額', style: text.labelMedium),
                const Spacer(),
                IconButton(
                  tooltip: '計算方法',
                  icon: const Icon(Icons.help_outline, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onHelpTap,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '¥${_fmt(log.provisionalEarnedYen)}',
              style: text.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.tertiary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              log.isFinalized ? '確定済み' : '本日暫定',
              style: text.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}
