import 'package:flutter/foundation.dart';

/// Google カレンダー連携前の MVP 用タスク。後から `eventId` 等を追加可能。
@immutable
class CalendarTask {
  const CalendarTask({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.rewardYen,
  });

  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final int rewardYen;
}
