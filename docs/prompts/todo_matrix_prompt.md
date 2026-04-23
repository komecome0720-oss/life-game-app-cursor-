# タスク: 3枚目のプライマリータブ「ToDo（Eisenhower Matrix）」実装

## ゴール

`lib/main.dart` の `_MainShell` に3枚目のプライマリータブ「ToDo」を追加し、
Eisenhower Matrix（2x2）のドラッグ＆ドロップ式 ToDo 画面を実装する。
長押しドラッグ中に画面上部から出現するカレンダーへタスクをドロップすると、
ホーム画面の週間スケジュールにシームレスに遷移して時刻スロットに配置できる。

## プロジェクト前提（必ず遵守）

- Flutter + Riverpod + Firebase Firestore（既存）
- MVVM + feature-first 構成（`lib/features/<feature>/{model,data,viewmodel,view,widgets}`）
- Provider / GetX は使わない（Riverpod のみ）
- コメントは日本語OK
- Dart 命名規則準拠（クラス UpperCamelCase、変数 lowerCamelCase）
- 既存の `lib/models/calendar_task.dart` と `lib/widgets/week_schedule_panel.dart`
  （`LongPressDraggable<CalendarTask>` + `DragTarget<CalendarTask>` が既に動いている）を参考に、
  同じ型でドラッグ受け渡しできるようにする

## データモデル（重要: 既存 tasks を拡張する）

`users/{uid}/tasks/{taskId}` に以下フィールドを追加して 1 コレクションで統合運用する。

- `isTodo: bool`（true のとき ToDo マトリクス側に表示。false のときカレンダー側）
- `urgency: bool`（true=緊急=上段）
- `importance: bool`（true=重要=右列）
- `orderIndex: int`（同一象限内での並び順、小さいほど上）
- `note: string?`（メモ、詳細シートで編集）
- `estimatedMinutes: int?`（予想所要時間、デフォルト 30）

`lib/models/calendar_task.dart` に対応するフィールドを追加し、`toMap` / `fromMap` を更新する。
`start` / `end` は `isTodo=true` の場合 null 許容に変更する（`DateTime?` 化）。
既存呼び出し箇所は null safety を維持しつつコンパイルが通る最小変更に留めること。

> 代替案: `CalendarTask` を壊したくない場合は `TodoTask` を別クラスで作り、
> `tasks` コレクション内に `isTodo` フラグと `start/end` null で保存する方式でも可。
> いずれにせよ **1 コレクション運用**であることが必須。

## 画面構成

### 1) ナビゲーション追加

`lib/main.dart` `_MainShell._pages` / `destinations` に ToDo を 3 枚目として追加。

- Icon: `Icons.checklist_outlined` / selected `Icons.checklist`
- Label: `'ToDo'`
- 遷移先: `const TodoMatrixScreen()`

### 2) ToDo 画面: `lib/features/todo/view/todo_matrix_screen.dart`

- 画面全体を 2x2 のマトリクスで表示
- 中央に十字線（`Divider` or `CustomPaint`、細線）
- 軸ラベル:
  - 画面左端に縦書き風に「重要じゃない ←→ 重要」
  - 画面上端に横ラベル「緊急 ／ 緊急じゃない」
- 4 象限の割当（ユーザー指定どおり）:
  - 左上: 緊急 × 重要じゃない
  - 右上: 緊急 × 重要（「すぐやる」）
  - 左下: 非緊急 × 重要じゃない（「やらない候補」）
  - 右下: 非緊急 × 重要（「計画的に」）
- 各象限は `DragTarget<CalendarTask>` で囲んだ `ListView`（縦スクロール）
- カード間の並び替えは `orderIndex` を更新
- 象限が空のときは中央にうっすら補助テキスト（例「ここにドラッグ」）

### 3) タスクカード: `lib/features/todo/widgets/todo_task_card.dart`

- 表示はタスク名のみ、`maxLines: 3`, `overflow: TextOverflow.ellipsis`
- 文字量によって高さが可変（最大 3 行）
- タップ → 詳細シート（後述）を `showModalBottomSheet`
- `LongPressDraggable<CalendarTask>`（既存 `week_schedule_panel.dart` と同型）で起動
  - `delay: const Duration(milliseconds: 300)` 程度
  - 起動と同時に `TodoMatrixScreen` に「カレンダー追加バー」を上からスライドイン表示（後述）
  - `feedback`: 半透明の同一カード（elevation 8、幅はドラッグ元と同じ）
  - `childWhenDragging`: 薄いプレースホルダ

### 4) 詳細シート: `lib/features/todo/widgets/todo_task_detail_sheet.dart`

`showModalBottomSheet` で表示。シンプル構成。

- タイトル（TextField、初期値入り）
- メモ（TextField、複数行）
- 予想所要時間（分、NumberPicker または Stepper、デフォルト 30）
- 緊急トグル / 重要トグル（象限を直接変更）
- 削除ボタン（確認ダイアログ後に削除）
- 保存ボタン（閉じつつ Firestore 更新）

### 5) 「カレンダーに追加」バー（上部からスライド）

`TodoMatrixScreen` 内に `AnimatedPositioned` または `SlideTransition` で実装。

- 高さ約 `1cm` → 論理ピクセルで `36–40 dp` を目安。iPhone のセーフエリアを考慮して `SafeArea` 外に重ねる
- 長押しドラッグ開始（`onDragStarted` 相当）で上からスルッと出る
- 中身: 左にカレンダーアイコン、右下に「カレンダーに追加」のラベル。角丸、ドロップ可能領域であることが一目でわかる枠線
- `DragTarget<CalendarTask>` にして、ホバー中は明るくハイライト
- ドラッグ終了で上にスライドアウト

### 6) カレンダーへドロップ時の体験（クロスタブドラッグ）

これがポイント。「指を離さずにホーム画面へ遷移し、そのまま週スケジュールのスロットへ配置」。

推奨実装: **`Overlay` と `GlobalKey` を用いたカスタムドラッグ**

1. `LongPressDraggable` の `onDragUpdate` でカレンダーバー上に指が乗ったら、
   `_MainShell` の `NavigationBar` selectedIndex を 0（ホーム）に切り替えつつ、
   ドラッグの `feedback` は `OverlayEntry` で画面最上層に描画継続。
2. 具体的には、`_MainShellState` に `ValueNotifier<Offset?> dragPosition` と
   `ValueNotifier<CalendarTask?> draggingTodo` を持たせる（または Riverpod Provider 経由）。
3. ToDo 側で `LongPressDraggable` を使うと画面遷移でドラッグが途切れる可能性があるので、
   `Listener` + 自前の `OverlayEntry` でドラッグゴーストを描画する実装も検討すること。
4. ゴーストの指位置を `WeekSchedulePanel` 側に公開し（Riverpod の `StateProvider<Offset?>`）、
   スケジュールの時刻スロットにホバー中はハイライトを出す。
5. `PointerUp` で以下を実行:
   - ヒット位置の `(day, timeSlot)` を計算
   - `CalendarTask` を `isTodo=false`、`urgency` / `importance` は保持、
     `start=timeSlot`、`end = start + estimatedMinutes (default 30 min)` に更新
   - Firestore 更新（`updateTask`）
6. 指がカレンダー外で離された場合は元の象限に戻す（`isTodo=true` のまま）

> クロスタブの指追従は Flutter 標準の `Draggable` 単独では難しいため、
> **`Overlay` + `Listener` パターン**を採用すること。
> 既存 `week_schedule_panel.dart` の `DragTarget<CalendarTask>` は流用できるよう、
> Drop 側の API は維持する（= 同じ型のペイロードを投げる）。

## Riverpod 構成

`lib/features/todo/`

- `data/todo_repository.dart`
  - `FirebaseFirestore` を受け取り、CRUD と stream
  - `Stream<List<CalendarTask>> watchTodos()` → `where('isTodo', isEqualTo: true)` + `orderBy('orderIndex')`
  - `Future<void> upsert(CalendarTask)`
  - `Future<void> updateQuadrant(id, {urgency, importance, orderIndex})`
  - `Future<void> convertToCalendarEvent(id, {DateTime start, DateTime end})`（`isTodo=false` + start/end を書き込む）
  - `Future<void> delete(id)`
- `providers/todo_providers.dart`
  - `todoRepositoryProvider`
  - `todosStreamProvider`（StreamProvider）
  - `draggingTodoProvider`（StateProvider、ドラッグ中のタスク）
  - `dragPositionProvider`（StateProvider、指の絶対座標）
- `viewmodel/todo_matrix_viewmodel.dart`
  - UI 状態とロジック（4 象限フィルタ、並び替え、象限変更、削除）

## UI 仕様・デザイン

- Material 3、既存 seedColor `0xFF2E7D6B` を踏襲
- 象限の背景色は薄いトーン分け（緊急×重要はやや赤系、非緊急×重要じゃないはグレー系）
- タスクカードは `Card` + `InkWell`、内側 padding 12、角丸 12、elevation 1
- ドラッグ中の feedback は elevation 8、若干スケール 1.03

## テスト・動作確認

- `flutter analyze` がクリーンに通ること
- 既存のビルドが壊れないこと（特に `CalendarTask` のフィールド追加で他の呼び出し箇所が破綻しないように）
- 手動確認シナリオ:
  1. ToDo タブに入り、FAB（右下）で新規タスク追加 → 右上象限（緊急×重要）に表示される
  2. 別象限にドラッグ → 象限が変わり、Firestore で `urgency` / `importance` が更新
  3. タップ → 詳細シート編集 → 保存で反映
  4. 長押し → 上部にカレンダーバー出現 → カレンダーに指をスライドすると ToDo タブからホームタブに自動切替、ゴーストが指について回る
  5. 週スケジュールのスロット上で指を離す → その時刻に 30 分の予定として登録され、ToDo 側からは消える
  6. 外れた場所でリリース → 元象限に戻る

## 既存コードとの接続ポイント

- `lib/main.dart` の `_MainShell`（NavigationBar / IndexedStack）
- `lib/widgets/week_schedule_panel.dart` の既存 `DragTarget<CalendarTask>` / `LongPressDraggable<CalendarTask>` を活かす
- `lib/models/calendar_task.dart` にフィールド追加（後方互換を維持）
- Firestore のセキュリティルール更新が必要な場合は `firestore.rules` に `isTodo` を許可リストに含む
  （owner-only の既存ルールで済むはず）

## 成果物

- 新規ファイル
  - `lib/features/todo/data/todo_repository.dart`
  - `lib/features/todo/providers/todo_providers.dart`
  - `lib/features/todo/viewmodel/todo_matrix_viewmodel.dart`
  - `lib/features/todo/view/todo_matrix_screen.dart`
  - `lib/features/todo/widgets/todo_task_card.dart`
  - `lib/features/todo/widgets/todo_task_detail_sheet.dart`
  - `lib/features/todo/widgets/calendar_drop_bar.dart`
  - `lib/features/todo/widgets/todo_quadrant.dart`
- 既存ファイル変更
  - `lib/main.dart`
  - `lib/models/calendar_task.dart`
  - 週スケジュールの `DragTarget` 連携で必要な最小限の変更

## 質問せず実装方針だけ迷ったら

- 軸ラベルや象限色は Material 3 のトーンでよしなに（ユーザー確認は不要）
- 新規作成の入口は ToDo 画面右下の FAB。タップでタイトル入力ダイアログのみの最小フロー
- 既定は `urgency=true`、`importance=true` で作成（右上に入る）
