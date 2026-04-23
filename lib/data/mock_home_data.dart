import 'package:task_manager/models/calendar_task.dart';
import 'package:task_manager/models/health_scores.dart';
import 'package:task_manager/models/user_profile.dart';

/// 週の開始（指定曜日 0:00）を返す。[startDay] は ISO 形式で 1=月…7=日。
DateTime startOfWeek(DateTime date, int startDay) {
  final d = DateTime(date.year, date.month, date.day);
  final weekday = d.weekday; // 1=Mon ... 7=Sun
  final diff = (weekday - startDay + 7) % 7;
  return d.subtract(Duration(days: diff));
}

/// 月曜を週開始とする慣用ショートカット。
DateTime startOfWeekMonday(DateTime date) => startOfWeek(date, DateTime.monday);

UserProfile mockUserProfile() => const UserProfile(
      displayName: 'プレイヤー',
      level: 12,
      balanceYen: 45800,
      hourlyRateYen: 3500,
    );

HealthScores mockHealthScores() => const HealthScores(
      meal: 7,
      sleep: 6,
      exercise: 8,
      meditation: 4,
    );

/// MVP: 今週分のモック予定（Google カレンダー API に差し替え予定）
List<CalendarTask> mockWeekTasks(DateTime anchor) {
  final monday = startOfWeekMonday(anchor);
  String id(int dayOffset, int index) => 'mock-${monday.toIso8601String()}-$dayOffset-$index';

  CalendarTask at(int dayOffset, int hour, int minute, String title, int reward, int durationMin) {
    final start = monday.add(Duration(days: dayOffset, hours: hour, minutes: minute));
    final end = start.add(Duration(minutes: durationMin));
    return CalendarTask(
      id: id(dayOffset, hour * 60 + minute),
      title: title,
      start: start,
      end: end,
      rewardYen: reward,
    );
  }

  return [
    at(0, 9, 0, '企画ミーティング', 1200, 60),
    at(0, 14, 0, '設計レビュー', 800, 45),
    at(1, 10, 30, '実装タスク A', 1500, 90),
    at(2, 11, 0, 'ランチ打ち合わせ', 500, 60),
    at(3, 9, 30, '集中ブロック', 2000, 120),
    at(3, 16, 0, 'メール処理', 400, 30),
    at(4, 13, 0, '週次レポート', 1000, 60),
    at(5, 10, 0, '学習タイム', 900, 45),
    at(6, 15, 0, '週末振り返り', 600, 30),
  ];
}
