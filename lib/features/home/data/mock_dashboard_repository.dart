import '../../contests/domain/models/contest.dart';
import '../domain/models/dashboard_summary.dart';
import '../domain/repositories/dashboard_repository.dart';

class MockDashboardRepository implements DashboardRepository {
  const MockDashboardRepository();

  @override
  Future<DashboardSummary> fetchSummary() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    return const DashboardSummary(
      fortuneTitle: '今日运势',
      fortuneContent: '今日运势：大吉，宜刷题，忌盲交',
      fortuneGood: ['补一道模板题', '整理错题'],
      fortuneBad: ['盲交代码', '忘记取模'],
      fortuneRating: '大吉',
      recentContests: [
        Contest(
          id: 'contest-1',
          title: '洛谷入门赛 #1',
          category: '洛谷官方赛',
          rule: 'OI 赛制',
          status: ContestStatus.upcoming,
          startsAt: '2026-05-01 14:00',
        ),
        Contest(
          id: 'contest-2',
          title: '洛谷入门赛 #2',
          category: '洛谷官方赛',
          rule: 'IOI 赛制',
          status: ContestStatus.running,
          startsAt: '2026-05-08 14:00',
        ),
        Contest(
          id: 'contest-3',
          title: '洛谷入门赛 #3',
          category: '个人公开赛',
          rule: 'OI 赛制',
          status: ContestStatus.upcoming,
          startsAt: '2026-05-15 14:00',
        ),
      ],
    );
  }
}
