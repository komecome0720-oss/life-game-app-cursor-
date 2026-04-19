import 'package:flutter/material.dart';
import 'package:task_manager/data/mock_home_data.dart';
import 'package:task_manager/models/calendar_task.dart';
import 'package:task_manager/models/health_scores.dart';
import 'package:task_manager/models/user_profile.dart';
import 'package:task_manager/screens/task_completion_screen.dart';
import 'package:task_manager/widgets/health_panel.dart';
import 'package:task_manager/widgets/task_event_detail_sheet.dart';
import 'package:task_manager/widgets/user_status_panel.dart';
import 'package:task_manager/widgets/week_schedule_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late UserProfile _profile;
  late HealthScores _health;
  late List<CalendarTask> _tasks;
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _reloadFromMocks();
  }

  void _reloadFromMocks() {
    final now = DateTime.now();
    _weekStart = startOfWeekMonday(now);
    _profile = mockUserProfile();
    _health = mockHealthScores();
    _tasks = mockWeekTasks(now);
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ライフゲーム'),
        actions: [
          IconButton(
            tooltip: 'データ再読込（モック）',
            onPressed: () => setState(_reloadFromMocks),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: UserStatusPanel(profile: _profile)),
                    const SizedBox(width: 10),
                    Expanded(child: HealthPanel(scores: _health)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                flex: 7,
                child: WeekSchedulePanel(
                  weekStart: _weekStart,
                  tasks: _tasks,
                  onTaskTap: _openTask,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
