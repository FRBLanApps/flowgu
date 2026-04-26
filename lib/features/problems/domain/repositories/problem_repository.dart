import '../models/problem.dart';

abstract class ProblemRepository {
  Future<List<Problem>> fetchProblems({
    String keyword = '',
    ProblemDifficulty? difficulty,
    String? tag,
    ProblemSortOption sortOption = ProblemSortOption.idAsc,
  });

  Future<Problem> fetchProblemDetail(Problem problem);
}
