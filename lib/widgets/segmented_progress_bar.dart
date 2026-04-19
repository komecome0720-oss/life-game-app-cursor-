import 'package:flutter/material.dart';

/// 0〜[maxScore] を [segments] 個のブロックで表す（MVP: 各項目は max 10）
class SegmentedProgressBar extends StatelessWidget {
  const SegmentedProgressBar({
    super.key,
    required this.score,
    this.maxScore = 10,
    this.segments = 10,
    this.height = 8,
  });

  final int score;
  final int maxScore;
  final int segments;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final clamped = score.clamp(0, maxScore);
    final filled = (clamped / maxScore * segments).ceil().clamp(0, segments);

    return Row(
      children: List.generate(segments, (i) {
        final active = i < filled;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: height,
              decoration: BoxDecoration(
                color: active ? scheme.primary : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// 合計行用: 最大 [maxTotal] を [segments] 分割して塗りつぶし
class TotalSegmentedProgressBar extends StatelessWidget {
  const TotalSegmentedProgressBar({
    super.key,
    required this.totalScore,
    this.maxTotal = 40,
    this.segments = 10,
    this.height = 8,
  });

  final int totalScore;
  final int maxTotal;
  final int segments;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final clamped = totalScore.clamp(0, maxTotal);
    final filled = (clamped / maxTotal * segments).floor();
    final safeFilled = filled.clamp(0, segments);

    return Row(
      children: List.generate(segments, (i) {
        final active = i < safeFilled;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: active ? scheme.tertiary : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }),
    );
  }
}
