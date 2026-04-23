/// 食事・睡眠・運動・瞑想は 0〜10。
/// 合計は重み付けして100点満点（食事・睡眠 ×3、運動・瞑想 ×2）。
class HealthScores {
  const HealthScores({
    required this.meal,
    required this.sleep,
    required this.exercise,
    required this.meditation,
  });

  final int meal;
  final int sleep;
  final int exercise;
  final int meditation;

  static const int maxTotal = 100;

  int get total => meal * 3 + sleep * 3 + exercise * 2 + meditation * 2;
}
