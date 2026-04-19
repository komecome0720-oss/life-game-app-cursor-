// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:task_manager/main.dart';

void main() {
  testWidgets('Home shows status and week header', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('ja_JP');

    await tester.pumpWidget(const TaskManagerApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('プレイヤー'), findsWidgets);
    expect(find.textContaining('今週の予定'), findsOneWidget);
  });
}
