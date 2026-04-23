/// 健康ログの採点・報酬計算ユーティリティ
class HealthScoring {
  HealthScoring._();

  /// 0〜10 段階への変換。goal <= 0 の場合は 0。
  static int level(num current, num goal) {
    if (goal <= 0) return 0;
    final v = (current / goal * 10).round();
    if (v < 0) return 0;
    if (v > 10) return 10;
    return v;
  }

  /// 合計点(0〜100) と時間単価から、獲得金額を算出。
  /// 100点 = 1日分(24時間)の1/8 = 3時間分の時間単価。
  static int earningsForPoints(int points, double hourlyRate) {
    if (hourlyRate <= 0 || points <= 0) return 0;
    return (hourlyRate * 3 * points / 100).round();
  }
}
