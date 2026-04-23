import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager/features/user_settings/model/user_settings.dart';
import 'package:task_manager/features/user_settings/viewmodel/user_settings_viewmodel.dart';
import 'package:task_manager/features/user_settings/widgets/hourly_rate_display.dart';
import 'package:task_manager/features/user_settings/widgets/profile_image_picker.dart';

class UserSettingsScreen extends ConsumerStatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  ConsumerState<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends ConsumerState<UserSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _levelCtrl;
  late final TextEditingController _budgetCtrl;
  late final TextEditingController _daysCtrl;
  late final TextEditingController _minutesCtrl;
  late final TextEditingController _mealCtrl;
  late final TextEditingController _exerciseCtrl;
  late final TextEditingController _sleepHoursCtrl;
  late final TextEditingController _sleepMinsCtrl;
  late final TextEditingController _meditationCtrl;

  File? _pendingAvatarFile;
  int? _pendingPresetIndex;
  bool _initialized = false;

  double get _localHourlyRate {
    final budget = int.tryParse(_budgetCtrl.text) ?? 0;
    final days = int.tryParse(_daysCtrl.text) ?? 0;
    final mins = int.tryParse(_minutesCtrl.text) ?? 0;
    final totalMins = days * mins;
    if (totalMins <= 0) return 0;
    return budget / (totalMins / 60);
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _levelCtrl = TextEditingController();
    _budgetCtrl = TextEditingController();
    _daysCtrl = TextEditingController();
    _minutesCtrl = TextEditingController();
    _mealCtrl = TextEditingController();
    _exerciseCtrl = TextEditingController();
    _sleepHoursCtrl = TextEditingController();
    _sleepMinsCtrl = TextEditingController();
    _meditationCtrl = TextEditingController();

    for (final ctrl in [_budgetCtrl, _daysCtrl, _minutesCtrl]) {
      ctrl.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final ctrl in [_nameCtrl, _levelCtrl, _budgetCtrl, _daysCtrl, _minutesCtrl, _mealCtrl, _exerciseCtrl, _sleepHoursCtrl, _sleepMinsCtrl, _meditationCtrl]) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _initControllers(UserSettings s) {
    if (_initialized) return;
    _initialized = true;
    _nameCtrl.text = s.displayName;
    _levelCtrl.text = s.level <= 1 ? '' : '${s.level}';
    _budgetCtrl.text = s.monthlyBudget == 0 ? '' : '${s.monthlyBudget}';
    _daysCtrl.text = s.monthlyQuestDays == 0 ? '' : '${s.monthlyQuestDays}';
    _minutesCtrl.text = s.dailyQuestMinutes == 0 ? '' : '${s.dailyQuestMinutes}';
    _mealCtrl.text = s.mealGoalGrams == 0 ? '' : '${s.mealGoalGrams}';
    _exerciseCtrl.text = s.exerciseGoalMinutes == 0 ? '' : '${s.exerciseGoalMinutes}';
    _sleepHoursCtrl.text = s.sleepGoalHours == 0 ? '' : '${s.sleepGoalHours}';
    _sleepMinsCtrl.text = s.sleepGoalMinutesExtra == 0 ? '' : '${s.sleepGoalMinutesExtra}';
    _meditationCtrl.text = s.meditationGoalMinutes == 0 ? '' : '${s.meditationGoalMinutes}';
  }

  UserSettings _currentSettings() {
    final base = ref.read(userSettingsProvider).settings;
    return base.copyWith(
      displayName: _nameCtrl.text.trim(),
      level: int.tryParse(_levelCtrl.text) ?? 1,
      monthlyBudget: int.tryParse(_budgetCtrl.text) ?? 0,
      monthlyQuestDays: int.tryParse(_daysCtrl.text) ?? 0,
      dailyQuestMinutes: int.tryParse(_minutesCtrl.text) ?? 0,
      mealGoalGrams: int.tryParse(_mealCtrl.text) ?? 0,
      exerciseGoalMinutes: int.tryParse(_exerciseCtrl.text) ?? 0,
      sleepGoalHours: int.tryParse(_sleepHoursCtrl.text) ?? 0,
      sleepGoalMinutesExtra: int.tryParse(_sleepMinsCtrl.text) ?? 0,
      meditationGoalMinutes: int.tryParse(_meditationCtrl.text) ?? 0,
    );
  }

  void _showBalanceAdjustDialog() {
    final ctrl = TextEditingController();
    bool isAdding = true;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('所持金を増減'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ToggleButtons(
                isSelected: [isAdding, !isAdding],
                onPressed: (i) => setDialogState(() => isAdding = i == 0),
                borderRadius: BorderRadius.circular(8),
                children: const [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('受け取る (+)')),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('使う (−)')),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: '金額',
                  prefixText: '¥',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
            TextButton(
              onPressed: () {
                final amount = int.tryParse(ctrl.text) ?? 0;
                if (amount > 0) {
                  final delta = isAdding ? amount : -amount;
                  ref.read(userSettingsProvider.notifier).adjustBalance(delta);
                }
                Navigator.pop(ctx);
              },
              child: const Text('確定'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = ref.read(userSettingsProvider.notifier);

    String? avatarUrl;
    if (_pendingAvatarFile != null) {
      avatarUrl = await vm.uploadAvatar(_pendingAvatarFile!);
    }

    final updated = _currentSettings().copyWith(
      avatarUrl: avatarUrl ?? ref.read(userSettingsProvider).settings.avatarUrl,
    );
    vm.update(updated);

    final success = await vm.save();
    if (!mounted) return;

    final errorMsg = ref.read(userSettingsProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '保存しました' : (errorMsg ?? '保存に失敗しました')),
        backgroundColor: success ? null : Colors.red,
      ),
    );
    if (success) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userSettingsProvider);

    // ロード完了をストリームで検知
    ref.listen<UserSettingsState>(userSettingsProvider, (prev, next) {
      if (!next.isLoading && (prev == null || prev.isLoading)) {
        _initControllers(next.settings);
      }
    });

    // 既にロード済みの状態で画面を開いた場合（2回目以降）
    if (!state.isLoading && !_initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _initControllers(state.settings);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール設定'),
        actions: [
          state.isSaving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text('保存', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SectionHeader('基本情報'),
                  const SizedBox(height: 12),
                  Center(
                    child: ProfileImagePicker(
                      avatarUrl: _pendingPresetIndex != null ? '' : state.settings.avatarUrl,
                      onFileSelected: (file) => setState(() {
                        _pendingAvatarFile = file;
                        _pendingPresetIndex = null;
                      }),
                      onPresetSelected: (i) => setState(() {
                        _pendingPresetIndex = i;
                        _pendingAvatarFile = null;
                      }),
                    ),
                  ),
                  if (_pendingPresetIndex != null) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: presetAvatarColor(_pendingPresetIndex!).withOpacity(0.2),
                        child: Icon(presetAvatarIcon(_pendingPresetIndex!),
                            color: presetAvatarColor(_pendingPresetIndex!), size: 24),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _Field(
                    controller: _nameCtrl,
                    label: '名前',
                    validator: (v) => (v == null || v.trim().isEmpty) ? '名前を入力してください' : null,
                  ),
                  const SizedBox(height: 12),
                  _NumberField(
                    controller: _levelCtrl,
                    label: 'レベル',
                    suffix: '',
                    required: false,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (v != null && v.isNotEmpty && (n == null || n < 1)) return '1以上';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _BalanceRow(
                    balanceYen: state.settings.totalEarned,
                    onAdjust: _showBalanceAdjustDialog,
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader('報酬設定'),
                  const SizedBox(height: 12),
                  _NumberField(controller: _budgetCtrl, label: '① 月に使えるお金', suffix: '円',
                      validator: (v) => _validatePositive(v, '金額')),
                  const SizedBox(height: 12),
                  _NumberField(controller: _daysCtrl, label: '② 月のクエスト日数', suffix: '日',
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n <= 0) return '日数を入力してください';
                        if (n > 31) return '31日以下で入力してください';
                        return null;
                      }),
                  const SizedBox(height: 12),
                  _NumberField(controller: _minutesCtrl, label: '③ 1日の想定クエスト時間', suffix: '分',
                      validator: (v) => _validatePositive(v, '時間')),
                  const SizedBox(height: 12),
                  HourlyRateDisplay(hourlyRate: _localHourlyRate),
                  const SizedBox(height: 24),
                  _SectionHeader('健康目標'),
                  const SizedBox(height: 12),
                  _NumberField(controller: _mealCtrl, label: '食事目標（野菜の量）', suffix: 'g/日', required: false),
                  const SizedBox(height: 12),
                  _NumberField(controller: _exerciseCtrl, label: '運動目標', suffix: '分/日', required: false),
                  const SizedBox(height: 12),
                  // 睡眠目標：時間＋分
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _NumberField(
                          controller: _sleepHoursCtrl,
                          label: '睡眠目標',
                          suffix: '時間',
                          required: false,
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (v != null && v.isNotEmpty && (n == null || n < 0)) return '0以上';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NumberField(
                          controller: _sleepMinsCtrl,
                          label: '睡眠目標（分）',
                          suffix: '分',
                          required: false,
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (v != null && v.isNotEmpty && (n == null || n < 0 || n > 59)) return '0〜59';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _NumberField(controller: _meditationCtrl, label: '瞑想目標', suffix: '分/日', required: false),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  String? _validatePositive(String? v, String label) {
    final n = int.tryParse(v ?? '');
    if (n == null || n <= 0) return '$labelを入力してください';
    return null;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ));
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.label, this.validator});
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: validator,
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({required this.balanceYen, required this.onAdjust});
  final int balanceYen;
  final VoidCallback onAdjust;

  String _fmt(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: '所持金',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '¥${_fmt(balanceYen)}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '手動で増減',
            onPressed: onAdjust,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.suffix,
    this.validator,
    this.required = true,
  });
  final TextEditingController controller;
  final String label;
  final String suffix;
  final String? Function(String?)? validator;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}
