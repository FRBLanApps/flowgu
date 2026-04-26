import '../../../core/network/api_client.dart';
import '../../../core/network/luogu_json.dart';
import '../domain/models/contest.dart';
import '../domain/repositories/contest_repository.dart';
import 'offline_contest_catalog.dart';

class LuoguContestRepository implements ContestRepository {
  LuoguContestRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<List<Contest>> fetchOfficialContests() {
    return _fetchContests(
      official: true,
      fallback: OfflineContestCatalog.official,
    );
  }

  @override
  Future<List<Contest>> fetchPublicContests() {
    return _fetchContests(
      official: false,
      fallback: OfflineContestCatalog.public,
    );
  }

  @override
  Future<List<Contest>> fetchAtCoderContests() async {
    try {
      final html = await ApiClient(
        baseUrl: 'https://atcoder.jp',
      ).getText('/contests/');
      final contests = _parseAtCoderContests(html);
      if (contests.isNotEmpty) {
        return contests;
      }
    } on Object {
      // AtCoder pages may be blocked by CORS on Flutter Web; keep the tab usable.
    }

    return OfflineContestCatalog.atcoder;
  }

  @override
  Future<Contest> fetchContestDetail(Contest contest) async {
    if (contest.source == ContestSource.atcoder) {
      return _fetchAtCoderContestDetail(contest);
    }

    if (contest.id.startsWith('offline-')) {
      return contest;
    }

    try {
      final json = await _apiClient.getJson(
        '/contest/${contest.id}',
        responseType: LuoguResponseType.lentille,
      );
      final data = LuoguJson.unwrap(json);
      final detail = LuoguJson.mapAt(data, 'contest');
      if (detail.isEmpty) {
        return contest;
      }

      return _contestDetailFromJson(contest, detail, data);
    } on Object {
      return contest;
    }
  }

  Future<Contest> _fetchAtCoderContestDetail(Contest contest) async {
    try {
      final html = await ApiClient(
        baseUrl: 'https://atcoder.jp',
      ).getText('/contests/${contest.id}/tasks');
      final problems = _parseAtCoderProblems(contest.id, html);

      if (problems.isEmpty) {
        return contest;
      }

      return Contest(
        id: contest.id,
        title: contest.title,
        category: contest.category,
        rule: contest.rule,
        status: contest.status,
        startsAt: contest.startsAt,
        source: contest.source,
        duration: contest.duration,
        ratedRange: contest.ratedRange,
        problemCount: problems.length,
        url: contest.url,
        description: contest.description ?? 'AtCoder 比赛题目列表已接入，提交和榜单需要原站登录态。',
        problems: problems,
        canViewScoreboard: true,
      );
    } on Object {
      return contest;
    }
  }

  Future<List<Contest>> _fetchContests({
    required bool official,
    required List<Contest> fallback,
  }) async {
    try {
      final json = await _apiClient.getJson(
        '/contest/list',
        responseType: LuoguResponseType.lentille,
        query: const {
          'page': '1',
        },
      );
      final data = LuoguJson.unwrap(json);
      final contests = _extractContests(data)
          .whereType<Map>()
          .map((contest) => Map<String, Object?>.from(contest))
          .where((contest) => _isOfficial(contest) == official)
          .map(_contestFromJson)
          .toList(growable: false);

      if (contests.isNotEmpty) {
        return contests;
      }
    } on Object {
      // Keep Home and Contests usable when Flutter Web is blocked by CORS.
    }

    return fallback;
  }

  List<Object?> _extractContests(Map<String, Object?> data) {
    final contests = LuoguJson.listAt(data, const ['contests']);
    if (contests.isNotEmpty) {
      return contests;
    }

    final result = LuoguJson.listAt(data, const ['contests', 'result']);
    if (result.isNotEmpty) {
      return result;
    }

    return LuoguJson.listAt(data, const ['result']);
  }

  Contest _contestFromJson(Map<String, Object?> json) {
    final startTime =
        LuoguJson.intValue(json, const ['startTime', 'start'], fallback: 0);
    final endTime =
        LuoguJson.intValue(json, const ['endTime', 'end'], fallback: 0);
    final host = LuoguJson.mapAt(json, 'host');

    return Contest(
      id: LuoguJson.stringValue(json, const ['id', 'cid'], fallback: '0'),
      title: LuoguJson.stringValue(
        json,
        const ['name', 'title'],
        fallback: '未命名比赛',
      ),
      category: _isOfficial(json)
          ? '洛谷官方赛'
          : LuoguJson.stringValue(host, const ['name'], fallback: '个人公开赛'),
      rule: _ruleLabel(
        LuoguJson.intValue(
          json,
          const ['method', 'ruleType', 'rule'],
          fallback: 0,
        ),
      ),
      status: _statusFromTime(startTime, endTime),
      startsAt: _formatTime(startTime),
      source: ContestSource.luogu,
      problemCount:
          LuoguJson.intValue(json, const ['problemCount'], fallback: 0),
      url: 'https://www.luogu.com.cn/contest/${LuoguJson.stringValue(
        json,
        const ['id', 'cid'],
        fallback: '',
      )}',
      description: '比赛信息来自洛谷公开比赛列表。',
    );
  }

  Contest _contestDetailFromJson(
    Contest fallback,
    Map<String, Object?> contest,
    Map<String, Object?> root,
  ) {
    final startTime =
        LuoguJson.intValue(contest, const ['startTime'], fallback: 0);
    final endTime = LuoguJson.intValue(contest, const ['endTime'], fallback: 0);
    final host = LuoguJson.mapAt(contest, 'host');
    final problems = LuoguJson.listAt(root, const ['contestProblems'])
        .whereType<Map>()
        .map((item) => Map<String, Object?>.from(item))
        .map(_contestProblemFromJson)
        .where((problem) => problem.id.isNotEmpty)
        .toList(growable: false);
    final duration = endTime > startTime && startTime > 0
        ? _formatDuration(endTime - startTime)
        : fallback.duration;

    return Contest(
      id: LuoguJson.stringValue(
        contest,
        const ['id', 'cid'],
        fallback: fallback.id,
      ),
      title: LuoguJson.stringValue(
        contest,
        const ['name', 'title'],
        fallback: fallback.title,
      ),
      category: _isOfficial(contest)
          ? '洛谷官方赛'
          : LuoguJson.stringValue(
              host,
              const ['name'],
              fallback: fallback.category,
            ),
      rule: _ruleLabel(
        LuoguJson.intValue(
          contest,
          const ['method', 'ruleType', 'rule'],
          fallback: 0,
        ),
      ),
      status: _statusFromTime(startTime, endTime),
      startsAt: _formatTime(startTime),
      source: ContestSource.luogu,
      duration: duration,
      ratedRange: _ratedRange(contest, fallback.ratedRange),
      problemCount: LuoguJson.intValue(
        contest,
        const ['problemCount'],
        fallback: problems.length,
      ),
      url: fallback.url ?? 'https://www.luogu.com.cn/contest/${fallback.id}',
      description: LuoguJson.stringValue(
        contest,
        const ['description'],
        fallback: fallback.description ?? '',
      ),
      problems: problems,
      canViewScoreboard: root['canViewScoreboard'] == true,
      joined: root['joined'] == true,
    );
  }

  ContestProblem _contestProblemFromJson(Map<String, Object?> json) {
    final problem = LuoguJson.mapAt(json, 'problem');

    return ContestProblem(
      id: LuoguJson.stringValue(problem, const ['pid', 'id']),
      title: LuoguJson.stringValue(
        problem,
        const ['title', 'name'],
        fallback: '未命名题目',
      ),
      score: LuoguJson.intValue(json, const ['score'], fallback: 0),
      difficulty:
          LuoguJson.intValue(problem, const ['difficulty'], fallback: 0),
    );
  }

  bool _isOfficial(Map<String, Object?> json) {
    final host = LuoguJson.mapAt(json, 'host');
    return LuoguJson.intValue(host, const ['id', 'uid'], fallback: 0) == 1000 ||
        LuoguJson.stringValue(host, const ['name']).contains('洛谷官方');
  }

  ContestStatus _statusFromTime(int startTime, int endTime) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (startTime > now) {
      return ContestStatus.upcoming;
    }
    if (endTime == 0 || endTime > now) {
      return ContestStatus.running;
    }

    return ContestStatus.finished;
  }

  String _ruleLabel(int ruleType) {
    return switch (ruleType) {
      1 => 'IOI 赛制',
      2 => 'ACM 赛制',
      3 => '乐多赛制',
      _ => 'OI 赛制',
    };
  }

  String _formatTime(int timestamp) {
    if (timestamp <= 0) {
      return '时间待定';
    }

    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '${date.year}-$month-$day $hour:$minute';
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours <= 0) {
      return '$minutes 分钟';
    }
    if (minutes <= 0) {
      return '$hours 小时';
    }

    return '$hours 小时 $minutes 分钟';
  }

  String? _ratedRange(Map<String, Object?> contest, String? fallback) {
    final threshold = LuoguJson.mapAt(contest, 'eloThreshold');
    final min = LuoguJson.intValue(threshold, const ['min'], fallback: -1);
    final max = LuoguJson.intValue(threshold, const ['max'], fallback: -1);
    if (min >= 0 && max >= 0) {
      return '$min - $max';
    }
    if (min >= 0) {
      return '$min+';
    }
    if (max >= 0) {
      return '- $max';
    }

    return fallback;
  }

  List<Contest> _parseAtCoderContests(String html) {
    final contests = <Contest>[];
    final seen = <String>{};
    final linkPattern = RegExp(
      r'<a href="/contests/([^"]+)">(?:[^<]*?)([^<]+)</a>',
      caseSensitive: false,
    );

    for (final match in linkPattern.allMatches(html)) {
      final id = match.group(1);
      final title = _decodeHtml(match.group(2) ?? '').trim();
      if (id == null || id.isEmpty || title.isEmpty || seen.contains(id)) {
        continue;
      }
      if (!RegExp(
        r'^(abc|arc|agc|ahc|practice|typical|dp)',
        caseSensitive: false,
      ).hasMatch(id)) {
        continue;
      }

      seen.add(id);
      contests.add(
        Contest(
          id: id,
          title: title,
          category: _atCoderCategory(id),
          rule: 'AtCoder',
          status: ContestStatus.upcoming,
          startsAt: '时间见原站',
          source: ContestSource.atcoder,
          url: 'https://atcoder.jp/contests/$id',
          description: 'AtCoder 公开比赛，题目、榜单和提交入口可在原站查看。',
        ),
      );

      if (contests.length >= 20) {
        break;
      }
    }

    return contests;
  }

  List<ContestProblem> _parseAtCoderProblems(String contestId, String html) {
    final problems = <ContestProblem>[];
    final seen = <String>{};
    final taskPattern = RegExp(
      r'<a href="/contests/' +
          RegExp.escape(contestId) +
          r'/tasks/([^"]+)">([^<]+)</a>',
      caseSensitive: false,
    );

    for (final match in taskPattern.allMatches(html)) {
      final id = match.group(1) ?? '';
      final title = _decodeHtml(match.group(2) ?? '').trim();
      if (id.isEmpty || title.isEmpty || seen.contains(id)) {
        continue;
      }

      seen.add(id);
      problems.add(
        ContestProblem(
          id: id,
          title: title,
        ),
      );
    }

    return problems;
  }

  String _atCoderCategory(String id) {
    if (id.startsWith('abc')) {
      return 'AtCoder Beginner Contest';
    }
    if (id.startsWith('arc')) {
      return 'AtCoder Regular Contest';
    }
    if (id.startsWith('agc')) {
      return 'AtCoder Grand Contest';
    }
    if (id.startsWith('ahc')) {
      return 'AtCoder Heuristic Contest';
    }

    return 'AtCoder';
  }

  String _decodeHtml(String value) {
    return value
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
  }
}
