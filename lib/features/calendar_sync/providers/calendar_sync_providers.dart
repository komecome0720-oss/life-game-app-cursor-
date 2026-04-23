import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager/features/calendar_sync/data/calendar_task_sync_repository.dart';
import 'package:task_manager/features/calendar_sync/data/google_calendar_repository.dart';
import 'package:task_manager/features/calendar_sync/viewmodel/calendar_sync_viewmodel.dart';
import 'package:task_manager/models/calendar_task.dart';

final googleCalendarRepositoryProvider = Provider<GoogleCalendarRepository>(
  (_) => GoogleCalendarRepository(),
);

final calendarTaskSyncRepositoryProvider = Provider<CalendarTaskSyncRepository>(
  (_) => CalendarTaskSyncRepository(),
);

final calendarSyncViewModelProvider =
    NotifierProvider<CalendarSyncViewModel, CalendarSyncState>(
  CalendarSyncViewModel.new,
);

/// Googleカレンダーごとの色マップ。カレンダー取得後に populate される。
/// 再起動後は空。次回 "取得" 時に再ロードされるまで Google イベントは
/// フォールバック色で表示される（MVP仕様：Firestore永続化は別途）。
final calendarColorsProvider = Provider<Map<String, Color>>((ref) {
  final calendars = ref.watch(calendarSyncViewModelProvider).calendars;
  final map = <String, Color>{};
  for (final c in calendars) {
    final hex = c.colorHex;
    if (hex == null) continue;
    final parsed = _parseHexColor(hex);
    if (parsed != null) map[c.id] = parsed;
  }
  return map;
});

/// 非表示にするカレンダーIDの集合。Drawer のチェックで切替。
/// MVPではin-memoryのみ（アプリ再起動でリセット）。
class HiddenCalendarIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  void setHidden(String calendarId, bool hidden) {
    if (hidden) {
      state = {...state, calendarId};
    } else {
      state = state.where((e) => e != calendarId).toSet();
    }
  }
}

final hiddenCalendarIdsProvider =
    NotifierProvider<HiddenCalendarIdsNotifier, Set<String>>(
  HiddenCalendarIdsNotifier.new,
);

/// タスクのLongPressDraggableがドラッグ中かどうか。
/// 日ビューで画面端ホバー時の自動ページングに使用。
class IsDraggingTaskNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setDragging(bool v) => state = v;
}

final isDraggingTaskProvider =
    NotifierProvider<IsDraggingTaskNotifier, bool>(
  IsDraggingTaskNotifier.new,
);

Color? _parseHexColor(String hex) {
  var clean = hex.replaceAll('#', '').trim();
  if (clean.length == 6) clean = 'FF$clean';
  if (clean.length != 8) return null;
  final value = int.tryParse(clean, radix: 16);
  return value == null ? null : Color(value);
}

/// 指定週（月曜 0:00 ローカル）の Firestore タスクをリアルタイム監視する。
/// 取り込み後に自動更新される。
final weekTasksProvider =
    StreamProvider.autoDispose.family<List<CalendarTask>, DateTime>(
        (ref, weekStart) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);

  final weekEnd = weekStart.add(const Duration(days: 7));

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('tasks')
      .where('startAtUtc',
          isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart.toUtc()))
      .where('startAtUtc',
          isLessThan: Timestamp.fromDate(weekEnd.toUtc()))
      .orderBy('startAtUtc')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => CalendarTask.fromMap(doc.id, doc.data()))
          .toList());
});
