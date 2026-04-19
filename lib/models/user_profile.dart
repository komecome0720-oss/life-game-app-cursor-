/// MVP: 左上ブロック用のユーザーステータス（のちに永続化・APIと接続）
class UserProfile {
  const UserProfile({
    required this.displayName,
    required this.level,
    required this.balanceYen,
    required this.hourlyRateYen,
  });

  final String displayName;
  final int level;
  final int balanceYen;
  final int hourlyRateYen;
}
