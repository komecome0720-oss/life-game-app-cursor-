import 'package:flutter/material.dart';
import 'package:task_manager/models/user_profile.dart';

class UserStatusPanel extends StatelessWidget {
  const UserStatusPanel({super.key, required this.profile});

  final UserProfile profile;

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
            Text('ステータス', style: text.labelMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 6),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _line(Icons.badge_outlined, '名前', profile.displayName, text),
                    _line(Icons.trending_up, 'レベル', '${profile.level}', text),
                    _line(Icons.savings_outlined, '所持金', '¥${_formatMoney(profile.balanceYen)}', text),
                    _line(Icons.schedule, '時間単価', '¥${_formatMoney(profile.hourlyRateYen)}/h', text),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(IconData icon, String label, String value, TextTheme text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Expanded(
            flex: 4,
            child: Text(label, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 6,
            child: Text(value, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  String _formatMoney(int n) {
    return n.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}
