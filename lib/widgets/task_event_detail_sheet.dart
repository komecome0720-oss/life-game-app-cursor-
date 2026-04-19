import 'dart:async';

import 'package:flutter/material.dart';
import 'package:task_manager/models/calendar_task.dart';

/// 予定タップ時のボトムシート: 報酬・タイマー・完了
Future<void> showTaskEventDetailSheet({
  required BuildContext context,
  required CalendarTask task,
  required VoidCallback onComplete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _TaskEventDetailBody(task: task, onComplete: onComplete),
    ),
  );
}

class _TaskEventDetailBody extends StatefulWidget {
  const _TaskEventDetailBody({required this.task, required this.onComplete});

  final CalendarTask task;
  final VoidCallback onComplete;

  @override
  State<_TaskEventDetailBody> createState() => _TaskEventDetailBodyState();
}

class _TaskEventDetailBodyState extends State<_TaskEventDetailBody> {
  Stopwatch? _stopwatch;
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_stopwatch?.isRunning ?? false) {
      _stopwatch!.stop();
      _ticker?.cancel();
      _ticker = null;
    } else {
      _stopwatch ??= Stopwatch()..start();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
    setState(() {});
  }

  String _elapsedLabel() {
    final d = _stopwatch?.elapsed ?? Duration.zero;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final running = _stopwatch?.isRunning ?? false;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.task.title, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.paid_outlined, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'このタスクを達成すると',
                      style: text.bodySmall?.copyWith(color: scheme.onPrimaryContainer),
                    ),
                  ),
                  Text(
                    '¥${_formatYen(widget.task.rewardYen)}',
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: scheme.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('タイマー', style: text.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: _toggleTimer,
                  icon: Icon(running ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  label: Text(running ? '一時停止' : '再生'),
                ),
                const SizedBox(width: 12),
                Text(
                  _elapsedLabel(),
                  style: text.headlineSmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                _ticker?.cancel();
                Navigator.of(context).pop();
                widget.onComplete();
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('チェック（完了へ）'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatYen(int n) {
    return n.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}
