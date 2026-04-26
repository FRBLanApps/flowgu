import '../domain/models/problem.dart';

class OfflineProblemCatalog {
  const OfflineProblemCatalog._();

  static List<Problem> search({
    String keyword = '',
    ProblemDifficulty? difficulty,
    String? tag,
    ProblemSortOption sortOption = ProblemSortOption.idAsc,
  }) {
    final normalizedKeyword = keyword.trim().toLowerCase();
    final normalizedTag = tag?.trim().toLowerCase();

    final filtered = problems.where((problem) {
      final matchesKeyword = normalizedKeyword.isEmpty ||
          problem.id.toLowerCase().contains(normalizedKeyword) ||
          problem.title.toLowerCase().contains(normalizedKeyword);
      final matchesDifficulty =
          difficulty == null || problem.difficulty == difficulty;
      final matchesTag = normalizedTag == null ||
          normalizedTag.isEmpty ||
          problem.tags.any((item) => item.toLowerCase() == normalizedTag);

      return matchesKeyword && matchesDifficulty && matchesTag;
    }).toList();

    _sort(filtered, sortOption);
    return filtered;
  }

  static Problem enrich(Problem problem) {
    if (problem.id == 'P1001') {
      return const Problem(
        id: 'P1001',
        title: 'A+B Problem',
        difficulty: ProblemDifficulty.beginner,
        acceptRate: 57.6,
        isAccepted: false,
        tags: ['模拟', '入门', '数学'],
        background: '算法竞赛的输出格式不能包含多余提示文本。',
        description: '输入两个整数 a, b，输出它们的和。|a|, |b| <= 10^9。',
        inputFormat: '两个以空格分开的整数。',
        outputFormat: '一个整数。',
        samples: [
          ProblemSample(input: '20 30', output: '50'),
        ],
        hint: '请只输出答案本身，不要输出提示语。',
        timeLimit: '1s',
        memoryLimit: '512MB',
      );
    }

    return problem;
  }

  static void _sort(List<Problem> problems, ProblemSortOption sortOption) {
    switch (sortOption) {
      case ProblemSortOption.idAsc:
        problems.sort((a, b) => a.id.compareTo(b.id));
      case ProblemSortOption.idDesc:
        problems.sort((a, b) => b.id.compareTo(a.id));
      case ProblemSortOption.difficultyAsc:
        problems
            .sort((a, b) => a.difficulty.index.compareTo(b.difficulty.index));
      case ProblemSortOption.difficultyDesc:
        problems
            .sort((a, b) => b.difficulty.index.compareTo(a.difficulty.index));
      case ProblemSortOption.acceptRateDesc:
        problems.sort((a, b) => b.acceptRate.compareTo(a.acceptRate));
      case ProblemSortOption.acceptRateAsc:
        problems.sort((a, b) => a.acceptRate.compareTo(b.acceptRate));
    }
  }

  static const problems = [
    Problem(
      id: 'P1000',
      title: '超级玛丽游戏',
      difficulty: ProblemDifficulty.beginner,
      acceptRate: 38.2,
      isAccepted: false,
      tags: ['模拟', '输出格式'],
      description: '入门输出题，适合检查环境和基础格式。',
      timeLimit: '1s',
      memoryLimit: '125MB',
    ),
    Problem(
      id: 'P1001',
      title: 'A+B Problem',
      difficulty: ProblemDifficulty.beginner,
      acceptRate: 57.6,
      isAccepted: false,
      tags: ['模拟', '入门', '数学'],
      description: '读取两个整数并输出它们的和。',
      timeLimit: '1s',
      memoryLimit: '125MB',
    ),
    Problem(
      id: 'P1002',
      title: '[NOIP 2002 普及组] 过河卒',
      difficulty: ProblemDifficulty.easy,
      acceptRate: 30.0,
      isAccepted: false,
      tags: ['动态规划', '递推'],
      description: '棋盘路径计数问题，避开马控制的位置。',
    ),
    Problem(
      id: 'P1003',
      title: '[NOIP 2011 提高组] 铺地毯',
      difficulty: ProblemDifficulty.easy,
      acceptRate: 34.9,
      isAccepted: false,
      tags: ['模拟', '枚举'],
    ),
    Problem(
      id: 'P1004',
      title: '[NOIP 2000 提高组] 方格取数',
      difficulty: ProblemDifficulty.medium,
      acceptRate: 47.2,
      isAccepted: false,
      tags: ['动态规划', '多维 DP'],
    ),
    Problem(
      id: 'P1005',
      title: '[NOIP 2007 提高组] 矩阵取数游戏',
      difficulty: ProblemDifficulty.medium,
      acceptRate: 31.8,
      isAccepted: false,
      tags: ['动态规划', '区间 DP', '高精度'],
    ),
    Problem(
      id: 'P1006',
      title: '[NOIP 2008 提高组] 传纸条',
      difficulty: ProblemDifficulty.medium,
      acceptRate: 43.3,
      isAccepted: false,
      tags: ['动态规划'],
    ),
    Problem(
      id: 'P1007',
      title: '独木桥',
      difficulty: ProblemDifficulty.easy,
      acceptRate: 41.7,
      isAccepted: false,
      tags: ['贪心', '数学'],
    ),
    Problem(
      id: 'P1008',
      title: '[NOIP 1998 普及组] 三连击',
      difficulty: ProblemDifficulty.easy,
      acceptRate: 48.8,
      isAccepted: false,
      tags: ['枚举', '模拟'],
    ),
    Problem(
      id: 'P1009',
      title: '[NOIP 1998 普及组] 阶乘之和',
      difficulty: ProblemDifficulty.easy,
      acceptRate: 25.2,
      isAccepted: false,
      tags: ['高精度', '数学'],
    ),
    Problem(
      id: 'P1010',
      title: '[NOIP 1998 普及组] 幂次方',
      difficulty: ProblemDifficulty.easy,
      acceptRate: 63.7,
      isAccepted: false,
      tags: ['递归', '分治'],
    ),
    Problem(
      id: 'P1012',
      title: '[NOIP 1998 提高组] 拼数',
      difficulty: ProblemDifficulty.medium,
      acceptRate: 45.7,
      isAccepted: false,
      tags: ['排序', '贪心', '字符串'],
    ),
    Problem(
      id: 'P1020',
      title: '[NOIP 1999 提高组] 导弹拦截',
      difficulty: ProblemDifficulty.medium,
      acceptRate: 20.5,
      isAccepted: false,
      tags: ['动态规划', '最长上升子序列'],
    ),
    Problem(
      id: 'P1024',
      title: '[NOIP 2001 提高组] 一元三次方程求解',
      difficulty: ProblemDifficulty.easy,
      acceptRate: 37.6,
      isAccepted: false,
      tags: ['二分', '数学'],
    ),
    Problem(
      id: 'P1048',
      title: '[NOIP 2005 普及组] 采药',
      difficulty: ProblemDifficulty.easy,
      acceptRate: 48.2,
      isAccepted: false,
      tags: ['动态规划', '背包'],
    ),
  ];
}
