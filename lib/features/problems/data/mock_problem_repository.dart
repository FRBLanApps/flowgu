import '../domain/models/problem.dart';
import '../domain/repositories/problem_repository.dart';

class MockProblemRepository implements ProblemRepository {
  const MockProblemRepository();

  @override
  Future<List<Problem>> fetchProblems({
    String keyword = '',
    ProblemDifficulty? difficulty,
    String? tag,
    ProblemSortOption sortOption = ProblemSortOption.idAsc,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final problems = List.generate(30, (index) {
      final difficulty =
          ProblemDifficulty.values[index % ProblemDifficulty.values.length];

      return Problem(
        id: 'P${1000 + index}',
        title: index == 0 ? 'A+B Problem' : '模板题 ${index + 1}',
        difficulty: difficulty,
        acceptRate: 50 + index % 40 + 0.1,
        isAccepted: index % 4 == 0,
        tags: index.isEven ? const ['动态规划', '模拟'] : const ['数学', '贪心'],
      );
    });

    final normalizedTag = tag?.trim().toLowerCase();
    final filtered = problems.where((problem) {
      final matchesKeyword = keyword.isEmpty ||
          problem.id.toLowerCase().contains(keyword.toLowerCase()) ||
          problem.title.toLowerCase().contains(keyword.toLowerCase());
      final matchesDifficulty =
          difficulty == null || problem.difficulty == difficulty;
      final matchesTag = normalizedTag == null ||
          normalizedTag.isEmpty ||
          problem.tags.any((item) => item.toLowerCase() == normalizedTag);

      return matchesKeyword && matchesDifficulty && matchesTag;
    }).toList();

    switch (sortOption) {
      case ProblemSortOption.idAsc:
        filtered.sort((a, b) => a.id.compareTo(b.id));
      case ProblemSortOption.idDesc:
        filtered.sort((a, b) => b.id.compareTo(a.id));
      case ProblemSortOption.difficultyAsc:
        filtered
            .sort((a, b) => a.difficulty.index.compareTo(b.difficulty.index));
      case ProblemSortOption.difficultyDesc:
        filtered
            .sort((a, b) => b.difficulty.index.compareTo(a.difficulty.index));
      case ProblemSortOption.acceptRateDesc:
        filtered.sort((a, b) => b.acceptRate.compareTo(a.acceptRate));
      case ProblemSortOption.acceptRateAsc:
        filtered.sort((a, b) => a.acceptRate.compareTo(b.acceptRate));
    }

    return filtered;
  }

  @override
  Future<Problem> fetchProblemDetail(Problem problem) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return problem;
  }
}
