import '../domain/models/contest.dart';

class OfflineContestCatalog {
  const OfflineContestCatalog._();

  static const official = [
    Contest(
      id: 'offline-official-1',
      title: '洛谷入门赛 #46',
      category: '洛谷官方赛',
      rule: 'OI 赛制',
      status: ContestStatus.upcoming,
      startsAt: '2026-05-01 14:00',
      problemCount: 4,
      problems: [
        ContestProblem(
          id: 'P1001',
          title: 'A+B Problem',
          score: 100,
          difficulty: 1,
        ),
      ],
    ),
    Contest(
      id: 'offline-official-2',
      title: '洛谷基础赛 #33',
      category: '洛谷官方赛',
      rule: 'OI 赛制',
      status: ContestStatus.upcoming,
      startsAt: '2026-05-08 14:00',
    ),
    Contest(
      id: 'offline-official-3',
      title: '洛谷月赛 Div.2',
      category: '洛谷官方赛',
      rule: 'OI 赛制',
      status: ContestStatus.upcoming,
      startsAt: '2026-05-15 14:00',
    ),
  ];

  static const public = [
    Contest(
      id: 'offline-public-1',
      title: '算法练习公开赛',
      category: '个人公开赛',
      rule: 'OI 赛制',
      status: ContestStatus.upcoming,
      startsAt: '2026-05-20 19:00',
      problemCount: 1,
      problems: [
        ContestProblem(
          id: 'P1001',
          title: 'A+B Problem',
          score: 100,
          difficulty: 1,
        ),
      ],
    ),
  ];

  static const atcoder = [
    Contest(
      id: 'abc456',
      title: 'AtCoder Beginner Contest 456',
      category: 'AtCoder Beginner Contest',
      rule: 'Rated',
      status: ContestStatus.upcoming,
      startsAt: '2026-05-02 21:00 JST',
      source: ContestSource.atcoder,
      duration: '01:40',
      ratedRange: '- 1999',
      problemCount: 8,
      url: 'https://atcoder.jp/contests/abc456',
      description: 'AtCoder Beginner Contest，面向入门到中级选手。',
      problems: [
        ContestProblem(id: 'abc456_a', title: 'A - Sample Task'),
        ContestProblem(id: 'abc456_b', title: 'B - Sample Task'),
      ],
    ),
    Contest(
      id: 'arc218',
      title: 'AtCoder Regular Contest 218',
      category: 'AtCoder Regular Contest',
      rule: 'Rated',
      status: ContestStatus.upcoming,
      startsAt: '2026-05-03 21:00 JST',
      source: ContestSource.atcoder,
      duration: '02:00',
      ratedRange: '1200 - 2799',
      problemCount: 6,
      url: 'https://atcoder.jp/contests/arc218',
      description: 'AtCoder Regular Contest，偏思维和证明。',
    ),
    Contest(
      id: 'abc455',
      title: 'AtCoder Beginner Contest 455',
      category: 'AtCoder Beginner Contest',
      rule: 'Rated',
      status: ContestStatus.finished,
      startsAt: '2026-04-25 21:00 JST',
      source: ContestSource.atcoder,
      duration: '01:40',
      ratedRange: '- 1999',
      problemCount: 8,
      url: 'https://atcoder.jp/contests/abc455',
      description: '近期 AtCoder Beginner Contest。',
    ),
  ];
}
