import 'package:flutter/material.dart';

class TaskCompletionScreen extends StatelessWidget {
  const TaskCompletionScreen({
    super.key,
    required this.taskTitle,
    required this.rewardYen,
  });

  final String taskTitle;
  final int rewardYen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('タスク完了')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Icon(Icons.celebration, size: 72, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              'おめでとう！',
              textAlign: TextAlign.center,
              style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              '「$taskTitle」を完了しました',
              textAlign: TextAlign.center,
              style: text.titleMedium,
            ),
            const SizedBox(height: 24),
            Text(
              '獲得（予定）: ¥${_formatYen(rewardYen)}',
              textAlign: TextAlign.center,
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: scheme.primary),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ホームに戻る'),
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
