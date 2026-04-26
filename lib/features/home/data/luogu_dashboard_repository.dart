import '../../contests/data/luogu_contest_repository.dart';
import '../../contests/domain/repositories/contest_repository.dart';
import '../domain/models/dashboard_summary.dart';
import '../domain/repositories/dashboard_repository.dart';

class LuoguDashboardRepository implements DashboardRepository {
  LuoguDashboardRepository({
    ContestRepository? contestRepository,
  }) : _contestRepository = contestRepository ?? LuoguContestRepository();

  final ContestRepository _contestRepository;

  @override
  Future<DashboardSummary> fetchSummary() async {
    final contests = await _contestRepository.fetchOfficialContests();
    final fortune = _dailyFortune();

    return DashboardSummary(
      fortuneTitle: '今日运势',
      fortuneContent: fortune.content,
      fortuneGood: fortune.good,
      fortuneBad: fortune.bad,
      fortuneRating: fortune.rating,
      recentContests: contests.take(3).toList(growable: false),
    );
  }

  _DailyFortune _dailyFortune() {
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    const goodPool = [
      '补一道模板题',
      '整理错题',
      '开一场虚拟赛',
      '写题解',
      '复习图论',
      '调试边界数据',
      '练习动态规划',
      '读清题面',
    ];
    const badPool = [
      '跳过样例',
      '临时改大结构',
      '忘记取模',
      '盲交代码',
      '熬夜硬刷',
      '忽略数据范围',
      '复制旧板子不检查',
      '把 long long 写成 int',
    ];
    const ratings = ['小吉', '中吉', '大吉', '平稳', '宜稳扎稳打'];

    List<String> pick(List<String> pool, int offset) {
      return [
        pool[(seed + offset) % pool.length],
        pool[(seed ~/ 7 + offset * 3) % pool.length],
      ];
    }

    final good = pick(goodPool, 3);
    final bad = pick(badPool, 5);
    final rating = ratings[seed % ratings.length];

    return _DailyFortune(
      rating: rating,
      content: '今日$statusPrefix$rating，宜${good.first}，忌${bad.first}',
      good: good,
      bad: bad,
    );
  }

  String get statusPrefix => '运势：';
}

class _DailyFortune {
  const _DailyFortune({
    required this.rating,
    required this.content,
    required this.good,
    required this.bad,
  });

  final String rating;
  final String content;
  final List<String> good;
  final List<String> bad;
}
