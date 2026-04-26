class UserProfile {
  const UserProfile({
    required this.name,
    required this.uid,
    required this.rankName,
    required this.acceptedCount,
    required this.submissionCount,
    required this.ranking,
    required this.valuation,
    this.avatarUrl,
    this.backgroundUrl,
    this.slogan,
    this.introduction,
  });

  final String name;
  final String uid;
  final String rankName;
  final int acceptedCount;
  final int submissionCount;
  final int ranking;
  final int valuation;
  final String? avatarUrl;
  final String? backgroundUrl;
  final String? slogan;
  final String? introduction;
}
