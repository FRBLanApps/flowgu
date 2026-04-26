enum ContestStatus {
  upcoming,
  running,
  finished,
}

enum ContestSource {
  luogu,
  atcoder,
}

class Contest {
  const Contest({
    required this.id,
    required this.title,
    required this.category,
    required this.rule,
    required this.status,
    required this.startsAt,
    this.source = ContestSource.luogu,
    this.duration,
    this.ratedRange,
    this.problemCount,
    this.url,
    this.description,
    this.problems = const [],
    this.canViewScoreboard = false,
    this.joined = false,
  });

  final String id;
  final String title;
  final String category;
  final String rule;
  final ContestStatus status;
  final String startsAt;
  final ContestSource source;
  final String? duration;
  final String? ratedRange;
  final int? problemCount;
  final String? url;
  final String? description;
  final List<ContestProblem> problems;
  final bool canViewScoreboard;
  final bool joined;

  String get sourceLabel {
    return switch (source) {
      ContestSource.luogu => '洛谷',
      ContestSource.atcoder => 'AtCoder',
    };
  }

  String get statusLabel {
    return switch (status) {
      ContestStatus.upcoming => '未开始',
      ContestStatus.running => '正在进行中',
      ContestStatus.finished => '已结束',
    };
  }
}

class ContestProblem {
  const ContestProblem({
    required this.id,
    required this.title,
    this.score,
    this.difficulty,
  });

  final String id;
  final String title;
  final int? score;
  final int? difficulty;
}
