import '../../../contests/domain/models/contest.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.fortuneTitle,
    required this.fortuneContent,
    required this.fortuneGood,
    required this.fortuneBad,
    required this.fortuneRating,
    required this.recentContests,
  });

  final String fortuneTitle;
  final String fortuneContent;
  final List<String> fortuneGood;
  final List<String> fortuneBad;
  final String fortuneRating;
  final List<Contest> recentContests;
}
