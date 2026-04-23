import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task_manager/models/calendar_task.dart';

class CalendarTaskSyncRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// [tasks] を Firestore へ upsert する。
  /// - externalCalendarId が同じ既存ドキュメントがあれば更新（isCompleted は保持）。
  /// - 未存在なら新規追加。
  Future<void> upsert(List<CalendarTask> tasks) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');
    if (tasks.isEmpty) return;

    final tasksCol = _db.collection('users').doc(uid).collection('tasks');

    final externalIds = tasks
        .map((t) => t.externalCalendarId)
        .whereType<String>()
        .toList();

    // whereIn の上限(30)に合わせてバッチ検索
    final existingRefs = <String, DocumentReference>{};
    for (var i = 0; i < externalIds.length; i += 30) {
      final chunk = externalIds.sublist(
        i,
        (i + 30) > externalIds.length ? externalIds.length : i + 30,
      );
      final snapshot = await tasksCol
          .where('externalCalendarId', whereIn: chunk)
          .get();
      for (final doc in snapshot.docs) {
        final extId = doc.data()['externalCalendarId'] as String?;
        if (extId != null) existingRefs[extId] = doc.reference;
      }
    }

    // WriteBatch で一括書き込み（上限500件。週1週間分なら通常問題なし）
    final batch = _db.batch();
    final serverNow = FieldValue.serverTimestamp();

    for (final task in tasks) {
      final extId = task.externalCalendarId;
      if (extId == null) continue;

      if (existingRefs.containsKey(extId)) {
        // 更新: isCompleted はユーザー操作値を保持するため除外
        final updateData = task.toMap()
          ..remove('isCompleted')
          ..['updatedAt'] = serverNow;
        batch.update(existingRefs[extId]!, updateData);
      } else {
        final ref = tasksCol.doc();
        batch.set(ref, task.toMap()..['updatedAt'] = serverNow);
      }
    }

    await batch.commit();
  }

  /// 手動タスクを新規作成する。
  Future<void> createTask({
    required String title,
    required DateTime start,
    required DateTime end,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');
    await _db.collection('users').doc(uid).collection('tasks').add({
      'title': title,
      'startAtUtc': Timestamp.fromDate(start.toUtc()),
      'endAtUtc': Timestamp.fromDate(end.toUtc()),
      'reward': 0,
      'sourceType': 'manual',
      'isAllDay': false,
      'isCompleted': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 指定タスクの開始・終了時刻を変更する。所要時間は [task] から算出。
  Future<void> moveTask(
    CalendarTask task,
    DateTime newStart,
    DateTime newEnd,
  ) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');
    await _db
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .doc(task.id)
        .update({
      'startAtUtc': Timestamp.fromDate(newStart.toUtc()),
      'endAtUtc': Timestamp.fromDate(newEnd.toUtc()),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// ToDo タスクをカレンダー予定に変換する（isTodo=false にして start/end を書き込む）。
  Future<void> convertToCalendarEvent({
    required String taskId,
    required DateTime start,
    required DateTime end,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');
    await _db
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .doc(taskId)
        .update({
      'isTodo': false,
      'startAtUtc': Timestamp.fromDate(start.toUtc()),
      'endAtUtc': Timestamp.fromDate(end.toUtc()),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
