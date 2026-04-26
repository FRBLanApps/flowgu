enum SubmissionResult {
  waiting,
  judging,
  compiling,
  accepted,
  wrongAnswer,
  timeLimitExceeded,
  runtimeError,
  compileError,
  unknown,
}

extension SubmissionResultLabel on SubmissionResult {
  String get resultLabel {
    return switch (this) {
      SubmissionResult.waiting => '等待',
      SubmissionResult.judging => '评测中',
      SubmissionResult.compiling => '编译中',
      SubmissionResult.accepted => 'AC',
      SubmissionResult.wrongAnswer => 'WA',
      SubmissionResult.timeLimitExceeded => 'TLE',
      SubmissionResult.runtimeError => 'RE',
      SubmissionResult.compileError => 'CE',
      SubmissionResult.unknown => '未知',
    };
  }
}

class SubmissionRecord {
  const SubmissionRecord({
    required this.id,
    required this.problemId,
    required this.problemTitle,
    required this.userName,
    required this.language,
    required this.duration,
    required this.memory,
    required this.submittedAt,
    required this.result,
    this.score,
    this.statusCode = 0,
    this.compileMessage,
    this.sourceCode,
    this.subtasks = const [],
  });

  final String id;
  final String problemId;
  final String problemTitle;
  final String userName;
  final String language;
  final String duration;
  final String memory;
  final String submittedAt;
  final SubmissionResult result;
  final int? score;
  final int statusCode;
  final String? compileMessage;
  final String? sourceCode;
  final List<SubmissionSubtask> subtasks;

  String get resultLabel {
    return result.resultLabel;
  }

  bool get isFinal {
    if (compileMessage != null && compileMessage!.trim().isNotEmpty) {
      return true;
    }

    return switch (result) {
      SubmissionResult.waiting ||
      SubmissionResult.judging ||
      SubmissionResult.compiling =>
        false,
      _ => true,
    };
  }
}

class SubmissionSubtask {
  const SubmissionSubtask({
    required this.id,
    required this.score,
    required this.status,
    required this.time,
    required this.memory,
    this.testCases = const [],
  });

  final int id;
  final int score;
  final SubmissionResult status;
  final int time;
  final int memory;
  final List<SubmissionTestCase> testCases;
}

class SubmissionTestCase {
  const SubmissionTestCase({
    required this.id,
    required this.status,
    required this.time,
    required this.memory,
    required this.score,
    this.description,
    this.signal,
    this.exitCode,
  });

  final int id;
  final SubmissionResult status;
  final int time;
  final int memory;
  final int score;
  final String? description;
  final int? signal;
  final int? exitCode;
}
