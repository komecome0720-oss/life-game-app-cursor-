import 'package:flutter/foundation.dart';

/// カレンダー選択ダイアログ用モデル。
@immutable
class GoogleCalendarSource {
  const GoogleCalendarSource({
    required this.id,
    required this.name,
    this.isPrimary = false,
    this.colorHex,
  });

  final String id;
  final String name;
  final bool isPrimary;
  final String? colorHex;
}
