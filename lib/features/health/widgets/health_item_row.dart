import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager/features/health/model/health_category.dart';
import 'package:task_manager/features/health/model/health_log.dart';
import 'package:task_manager/features/health/model/health_scoring.dart';
import 'package:task_manager/features/health/viewmodel/health_detail_viewmodel.dart';
import 'package:task_manager/features/user_settings/model/user_settings.dart';

/// 健康詳細画面の1カテゴリ分の行。3列レイアウト:
///   左: 目標値  / 中央: 現状値（スライダー）/ 右: 10段階・点数・カテゴリ獲得金額
class HealthItemRow extends ConsumerWidget {
  const HealthItemRow({
    super.key,
    required this.category,
    required this.log,
    required this.settings,
    required this.enabled,
  });

  final HealthCategory category;
  final HealthLog log;
  final UserSettings settings;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final current = category.currentValue(log);
    final level = category.level(log);
    final score = category.score(log);
    final maxPoints = category.maxPoints;
    final earnings =
        HealthScoring.earningsForPoints(score, settings.hourlyRate);

    // スライダー値は仕様の min/max にクランプして表示（記録値が仕様外でも表示できるように）
    final sliderValue = current
        .toDouble()
        .clamp(category.sliderMin, category.sliderMax);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(category.icon, size: 18, color: scheme.primary),
                const SizedBox(width: 6),
                Text(category.label,
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 左1/3: 目標値
                Expanded(
                  child: _LabelValue(
                    label: '目標',
                    value: category.goalValue(settings) == 0
                        ? '—'
                        : category.formatGoal(settings),
                  ),
                ),
                // 中央1/3: 現状値＋スライダー
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        category.formatValue(current),
                        textAlign: TextAlign.center,
                        style: text.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 14),
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8),
                        ),
                        child: Slider(
                          value: sliderValue,
                          min: category.sliderMin,
                          max: category.sliderMax,
                          divisions: category.sliderDivisions,
                          onChanged: enabled
                              ? (v) => ref
                                  .read(healthDetailViewModelProvider.notifier)
                                  .previewValue(category, v.round())
                              : null,
                          onChangeEnd: enabled
                              ? (v) => ref
                                  .read(healthDetailViewModelProvider.notifier)
                                  .commitValue(category, v.round())
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                // 右1/3: 上段=10段階/点数、下段=獲得金額
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      RichText(
                        textAlign: TextAlign.right,
                        text: TextSpan(
                          style: text.bodyMedium,
                          children: [
                            TextSpan(
                              text: '$level',
                              style: text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.primary,
                              ),
                            ),
                            const TextSpan(text: '/10'),
                          ],
                        ),
                      ),
                      Text(
                        '$score/$maxPoints点',
                        style: text.labelSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '+¥${_fmtYen(earnings)}',
                        style: text.titleSmall?.copyWith(
                          color: scheme.tertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmtYen(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.labelSmall),
        Text(value,
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
