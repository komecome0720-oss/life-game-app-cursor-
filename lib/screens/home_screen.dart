import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager/data/mock_home_data.dart';
import 'package:task_manager/features/auth/providers/auth_providers.dart';
import 'package:task_manager/features/calendar_sync/model/google_calendar_source.dart';
import 'package:task_manager/features/calendar_sync/providers/calendar_sync_providers.dart';
import 'package:task_manager/features/health/model/health_category.dart';
import 'package:task_manager/features/health/view/health_detail_screen.dart';
import 'package:task_manager/features/health/viewmodel/health_detail_viewmodel.dart';
import 'package:task_manager/features/user_settings/viewmodel/user_settings_viewmodel.dart';
import 'package:task_manager/models/calendar_task.dart';
import 'package:task_manager/models/health_scores.dart';
import 'package:task_manager/screens/task_completion_screen.dart';
import 'package:task_manager/widgets/health_panel.dart';
import 'package:task_manager/widgets/quick_create_sheet.dart';
import 'package:task_manager/widgets/task_event_detail_sheet.dart';
import 'package:task_manager/widgets/user_status_panel.dart';
import 'package:task_manager/widgets/week_schedule_panel.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const int _initialPage = 5000;

  late DateTime _baseWeekStart;
  late DateTime _baseDay;
  late PageController _weekPageController;
  late PageController _dayPageController;
  CalendarViewMode _viewMode = CalendarViewMode.week;
  int _currentWeekPage = _initialPage;
  int _currentDayPage = _initialPage;
  int _weekStartDay = DateTime.monday;

  bool get _isOnToday => _viewMode == CalendarViewMode.week
      ? _currentWeekPage == _initialPage
      : _currentDayPage == _initialPage;

  DateTime get _currentWeekStart => _viewMode == CalendarViewMode.week
      ? _weekStartForPage(_currentWeekPage)
      : startOfWeek(_dayForPage(_currentDayPage), _weekStartDay);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStartDay =
        ref.read(userSettingsProvider).settings.weekStartDay;
    _baseWeekStart = startOfWeek(now, _weekStartDay);
    _baseDay = DateTime(now.year, now.month, now.day);
    _weekPageController = PageController(initialPage: _initialPage);
    _dayPageController = PageController(initialPage: _initialPage);
  }

  Timer? _edgePagerTimer;

  @override
  void dispose() {
    _edgePagerTimer?.cancel();
    _weekPageController.dispose();
    _dayPageController.dispose();
    super.dispose();
  }

  // ── 日ビュードラッグ中の画面端ページング ─────────────────────

  void _handleDayDragPointerMove(PointerMoveEvent event) {
    if (!ref.read(isDraggingTaskProvider)) {
      _edgePagerTimer?.cancel();
      _edgePagerTimer = null;
      return;
    }
    const edgeWidth = 36.0;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final x = event.position.dx;
    if (x < edgeWidth) {
      _armEdgePager(forward: false);
    } else if (x > screenWidth - edgeWidth) {
      _armEdgePager(forward: true);
    } else {
      _edgePagerTimer?.cancel();
      _edgePagerTimer = null;
    }
  }

  void _armEdgePager({required bool forward}) {
    if (_edgePagerTimer != null) return;
    _edgePagerTimer = Timer(const Duration(milliseconds: 500), () {
      _edgePagerTimer = null;
      if (!mounted) return;
      if (!ref.read(isDraggingTaskProvider)) return;
      if (forward) {
        _dayPageController.nextPage(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      } else {
        _dayPageController.previousPage(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  DateTime _weekStartForPage(int index) =>
      _baseWeekStart.add(Duration(days: (index - _initialPage) * 7));

  DateTime _dayForPage(int index) =>
      _baseDay.add(Duration(days: index - _initialPage));

  Future<void> _openTask(CalendarTask task) async {
    await showTaskEventDetailSheet(
      context: context,
      task: task,
      onComplete: () {
        if (!mounted) return;
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (context) => TaskCompletionScreen(
              taskTitle: task.title,
              rewardYen: task.rewardYen,
            ),
          ),
        );
      },
    );
  }

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }

  // ── 空スロットタップでの予定追加 ───────────────────────────────

  Future<void> _handleEmptyTap(DateTime initialStart) async {
    final result = await showModalBottomSheet<(String, int)>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => QuickCreateSheet(initialStart: initialStart),
    );
    if (result == null || !mounted) return;
    final (title, durationMin) = result;
    final end = initialStart.add(Duration(minutes: durationMin));
    final vm = ref.read(calendarSyncViewModelProvider.notifier);
    final success =
        await vm.createTask(title: title, start: initialStart, end: end);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('予定を追加しました')),
      );
    } else {
      final errorMsg = ref.read(calendarSyncViewModelProvider).errorMessage;
      _showErrorSnackBar(errorMsg ?? '追加に失敗しました');
      vm.clearError();
    }
  }

  // ── カレンダー取り込みフロー ────────────────────────────────────

  Future<void> _handleImport(DateTime weekStart) async {
    final vm = ref.read(calendarSyncViewModelProvider.notifier);

    final calendars = await vm.loadCalendars();
    if (!mounted) return;

    final state = ref.read(calendarSyncViewModelProvider);
    if (state.errorMessage != null) {
      _showErrorSnackBar(state.errorMessage!);
      vm.clearError();
      return;
    }

    if (calendars.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('カレンダーが見つかりませんでした')),
      );
      return;
    }

    final selected = await _showCalendarSelectDialog(calendars);
    if (selected == null || !mounted) return;

    final success = await vm.importWeek(
      calendarId: selected.id,
      weekStart: weekStart,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('カレンダーから取り込みました')),
      );
    } else {
      final errorMsg = ref.read(calendarSyncViewModelProvider).errorMessage;
      _showErrorSnackBar(errorMsg ?? '取り込みに失敗しました',
          retry: () => _handleImport(weekStart));
      vm.clearError();
    }
  }

  void _showErrorSnackBar(String message, {VoidCallback? retry}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 8),
        action: retry != null
            ? SnackBarAction(
                label: '再試行',
                textColor: Colors.white,
                onPressed: retry,
              )
            : null,
      ),
    );
  }

  Future<GoogleCalendarSource?> _showCalendarSelectDialog(
    List<GoogleCalendarSource> calendars,
  ) {
    return showDialog<GoogleCalendarSource>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('カレンダーを選択'),
        children: calendars
            .map((cal) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, cal),
                  child: Row(
                    children: [
                      Icon(
                        cal.isPrimary ? Icons.star : Icons.calendar_today,
                        size: 16,
                        color: cal.isPrimary ? Colors.amber : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(cal.name)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  void _jumpToToday() {
    if (_viewMode == CalendarViewMode.week) {
      _weekPageController.jumpToPage(_initialPage);
    } else {
      _dayPageController.jumpToPage(_initialPage);
    }
  }

  void _handleViewModeChange(CalendarViewMode mode) {
    setState(() => _viewMode = mode);
  }

  // ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).asData?.value;
    final syncState = ref.watch(calendarSyncViewModelProvider);
    final syncCalendars = syncState.calendars;
    final calendarColors = ref.watch(calendarColorsProvider);
    final hidden = ref.watch(hiddenCalendarIdsProvider);

    // 週の始まり設定の変更を追従
    ref.listen<int>(
      userSettingsProvider.select((s) => s.settings.weekStartDay),
      (prev, next) {
        if (!mounted || prev == next) return;
        setState(() {
          _weekStartDay = next;
          _baseWeekStart = startOfWeek(DateTime.now(), next);
        });
      },
    );

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            tooltip: 'メニュー',
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text('ライフゲーム'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.displayName ?? 'ユーザー'),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  (user?.displayName?.isNotEmpty == true
                          ? user!.displayName![0]
                          : user?.email?[0] ?? '?')
                      .toUpperCase(),
                  style: TextStyle(
                      fontSize: 24,
                      color: Theme.of(context).colorScheme.primary),
                ),
              ),
              decoration:
                  BoxDecoration(color: Theme.of(context).colorScheme.primary),
            ),
            if (syncCalendars.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'カレンダー',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              ...syncCalendars.map((cal) {
                final isHidden = hidden.contains(cal.id);
                final color = calendarColors[cal.id];
                return CheckboxListTile(
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: !isHidden,
                  onChanged: (on) {
                    ref
                        .read(hiddenCalendarIdsProvider.notifier)
                        .setHidden(cal.id, on != true);
                  },
                  title: Text(
                    cal.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  secondary: color == null
                      ? null
                      : Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                );
              }),
              const Divider(),
            ],
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('ログアウト'),
              onTap: () async {
                Navigator.of(context).pop();
                await _signOut();
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Expanded(child: UserStatusPanel()),
                    const SizedBox(width: 10),
                    const Expanded(child: _HealthPanelConnector()),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ScheduleHeaderBar(
                        viewMode: _viewMode,
                        isOnToday: _isOnToday,
                        onViewModeChanged: _handleViewModeChange,
                        onJumpToToday: _jumpToToday,
                        onImportFromCalendar: () =>
                            _handleImport(_currentWeekStart),
                        isImporting: syncState.isLoading,
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: IndexedStack(
                          index:
                              _viewMode == CalendarViewMode.week ? 0 : 1,
                          children: [
                            PageView.builder(
                              controller: _weekPageController,
                              onPageChanged: (p) =>
                                  setState(() => _currentWeekPage = p),
                              itemBuilder: (context, index) {
                                final ws = _weekStartForPage(index);
                                final visibleDays = List.generate(
                                    7, (i) => ws.add(Duration(days: i)));
                                return _SchedulePage(
                                  visibleDays: visibleDays,
                                  onTaskTap: _openTask,
                                  onEmptyTap: _handleEmptyTap,
                                );
                              },
                            ),
                            Listener(
                              onPointerMove: _handleDayDragPointerMove,
                              child: PageView.builder(
                                controller: _dayPageController,
                                onPageChanged: (p) =>
                                    setState(() => _currentDayPage = p),
                                itemBuilder: (context, index) {
                                  final day = _dayForPage(index);
                                  return _SchedulePage(
                                    visibleDays: [day],
                                    onTaskTap: _openTask,
                                    onEmptyTap: _handleEmptyTap,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 可変日数（1〜7日）のパネル本体。対応週のタスクをwatch、非表示カレンダーと
/// visibleDays の範囲でフィルタして WeekSchedulePanel に渡す。ヘッダーは親で描画。
class _SchedulePage extends ConsumerWidget {
  const _SchedulePage({
    required this.visibleDays,
    required this.onTaskTap,
    required this.onEmptyTap,
  });

  final List<DateTime> visibleDays;
  final ValueChanged<CalendarTask> onTaskTap;
  final ValueChanged<DateTime> onEmptyTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = startOfWeekMonday(visibleDays.first);
    final tasksAsync = ref.watch(weekTasksProvider(weekStart));
    final allTasks = tasksAsync.asData?.value ?? const <CalendarTask>[];
    final hidden = ref.watch(hiddenCalendarIdsProvider);

    final dayKeys =
        visibleDays.map((d) => DateTime(d.year, d.month, d.day)).toSet();

    final visibleTasks = allTasks.where((t) {
      final ext = t.externalCalendarId;
      if (ext != null) {
        final idx = ext.indexOf(':');
        final calId = idx > 0 ? ext.substring(0, idx) : null;
        if (calId != null && hidden.contains(calId)) return false;
      }
      final start = t.start;
      if (start == null) return false;
      final taskDay = DateTime(start.year, start.month, start.day);
      return dayKeys.contains(taskDay);
    }).toList();

    return WeekSchedulePanel(
      visibleDays: visibleDays,
      tasks: visibleTasks,
      onTaskTap: onTaskTap,
      onEmptyTap: onEmptyTap,
    );
  }
}

/// 今日の健康ログ（VM 状態）を HealthPanel 用の HealthScores に変換し、
/// タップで健康詳細画面へ遷移する。
class _HealthPanelConnector extends ConsumerWidget {
  const _HealthPanelConnector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(healthDetailViewModelProvider).log;
    final scores = HealthScores(
      meal: HealthCategory.meal.level(log),
      sleep: HealthCategory.sleep.level(log),
      exercise: HealthCategory.exercise.level(log),
      meditation: HealthCategory.meditation.level(log),
    );
    return HealthPanel(
      scores: scores,
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const HealthDetailScreen()),
      ),
    );
  }
}
