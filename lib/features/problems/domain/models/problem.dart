enum ProblemDifficulty {
  unrated,
  beginner,
  easy,
  normal,
  medium,
  hard,
  provincial,
  noi,
}

enum ProblemSource {
  luogu,
  atcoder,
}

enum ProblemSortOption {
  idAsc,
  idDesc,
  difficultyAsc,
  difficultyDesc,
  acceptRateDesc,
  acceptRateAsc,
}

extension ProblemDifficultyExtension on ProblemDifficulty {
  String get difficultyLabel {
    return switch (this) {
      ProblemDifficulty.unrated => '暂无评定',
      ProblemDifficulty.beginner => '入门',
      ProblemDifficulty.easy => '普及-',
      ProblemDifficulty.normal => '普及/提高-',
      ProblemDifficulty.medium => '普及+/提高',
      ProblemDifficulty.hard => '提高+/省选-',
      ProblemDifficulty.provincial => '省选/NOI-',
      ProblemDifficulty.noi => 'NOI/NOI+/CTSC',
    };
  }
}

class Problem {
  const Problem({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.acceptRate,
    required this.isAccepted,
    this.source = ProblemSource.luogu,
    this.tags = const [],
    this.url,
    this.description,
    this.background,
    this.inputFormat,
    this.outputFormat,
    this.hint,
    this.samples = const [],
    this.timeLimit,
    this.memoryLimit,
    this.acceptLanguages = const [],
  });

  final String id;
  final String title;
  final ProblemDifficulty difficulty;
  final double acceptRate;
  final bool isAccepted;
  final ProblemSource source;
  final List<String> tags;
  final String? url;
  final String? description;
  final String? background;
  final String? inputFormat;
  final String? outputFormat;
  final String? hint;
  final List<ProblemSample> samples;
  final String? timeLimit;
  final String? memoryLimit;
  final List<int> acceptLanguages;

  String get difficultyLabel => difficulty.difficultyLabel;

  String get sourceLabel {
    return switch (source) {
      ProblemSource.luogu => '洛谷',
      ProblemSource.atcoder => 'AtCoder',
    };
  }
}

class ProblemSample {
  const ProblemSample({
    required this.input,
    required this.output,
  });

  final String input;
  final String output;
}
