import '../domain/models/contest.dart';
import '../domain/repositories/contest_repository.dart';

class MockContestRepository implements ContestRepository {
  const MockContestRepository();

  @override
  Future<List<Contest>> fetchOfficialContests() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    return List.generate(
      5,
      (index) => Contest(
        id: 'official-$index',
        title: 'Luogu OI Contest ${index + 1}',
        category: '洛谷官方赛',
        rule: index.isEven ? 'IOI 赛制' : 'OI 赛制',
        status: index == 0 ? ContestStatus.running : ContestStatus.upcoming,
        startsAt: '2026-05-${(index + 1).toString().padLeft(2, '0')} 14:00',
      ),
    );
  }

  @override
  Future<List<Contest>> fetchPublicContests() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    return const [
      Contest(
        id: 'public-1',
        title: '算法练习公开赛',
        category: '个人公开赛',
        rule: 'OI 赛制',
        status: ContestStatus.upcoming,
        startsAt: '2026-05-20 19:00',
      ),
    ];
  }

  @override
  Future<List<Contest>> fetchAtCoderContests() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    return const [
      Contest(
        id: 'abc456',
        title: 'AtCoder Beginner Contest 456',
        category: 'AtCoder',
        rule: 'Rated',
        status: ContestStatus.upcoming,
        startsAt: '2026-05-02 21:00 JST',
        source: ContestSource.atcoder,
        duration: '01:40',
        ratedRange: '- 1999',
        problemCount: 8,
        url: 'https://atcoder.jp/contests/abc456',
      ),
    ];
  }

  @override
  Future<Contest> fetchContestDetail(Contest contest) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    return contest;
  }
}
