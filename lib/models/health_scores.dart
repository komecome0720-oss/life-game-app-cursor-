/// 食事・睡眠・運動・瞑想は 0〜10。合計は4項目の合算。
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

  int get total => meal + sleep + exercise + meditation;
}
