import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manager/models/calendar_task.dart';

/// 週始まり [weekStart]（月曜 0:00）基準でタスクを列ごとに表示
class WeekSchedulePanel extends StatelessWidget {
  const WeekSchedulePanel({
    super.key,
    required this.weekStart,
    required this.tasks,
    required this.onTaskTap,
  });

  final DateTime weekStart;
  final List<CalendarTask> tasks;
  final ValueChanged<CalendarTask> onTaskTap;

  Map<int, List<CalendarTask>> _groupByDay() {
    final map = {for (var i = 0; i < 7; i++) i: <CalendarTask>[]};
    final origin = DateTime(weekStart.year, weekStart.month, weekStart.day);
    for (final t in tasks) {
      final day = DateTime(t.start.year, t.start.month, t.start.day);
      final diff = day.difference(origin).inDays;
      if (diff >= 0 && diff < 7) {
        map[diff]!.add(t);
      }
    }
    for (final list in map.values) {
      list.sort((a, b) => a.start.compareTo(b.start));
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final grouped = _groupByDay();
    final dayFmt = DateFormat.Md('ja_JP');
    final timeFmt = DateFormat.Hm('ja_JP');

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Icon(Icons.calendar_view_week, color: scheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '今週の予定（Googleカレンダー連携は今後対応）',
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(7, (dayOffset) {
                final day = weekStart.add(Duration(days: dayOffset));
                final dayTasks = grouped[dayOffset] ?? const <CalendarTask>[];
                return Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.35)),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${DateFormat.E('ja_JP').format(day)} ${dayFmt.format(day)}',
                            style: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: dayTasks.isEmpty
                                ? Center(
                                    child: Text(
                                      '予定なし',
                                      style: text.bodySmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: dayTasks.length,
                                    separatorBuilder: (context, index) => const SizedBox(height: 6),
                                    itemBuilder: (context, i) {
                                      final task = dayTasks[i];
                                      return Material(
                                        color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
                                        borderRadius: BorderRadius.circular(8),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(8),
                                          onTap: () => onTaskTap(task),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  timeFmt.format(task.start),
                                                  style: text.labelSmall?.copyWith(
                                                    color: scheme.primary,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  task.title,
                                                  style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                                  maxLines: 3,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
