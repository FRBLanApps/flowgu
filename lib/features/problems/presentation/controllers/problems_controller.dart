import 'package:flutter/foundation.dart';

import '../../../../core/utils/async_value.dart';
import '../../data/luogu_problem_repository.dart';
import '../../domain/models/problem.dart';
import '../../domain/repositories/problem_repository.dart';

class ProblemsController extends ChangeNotifier {
  ProblemsController({
    ProblemRepository? repository,
  }) : _repository = repository ?? LuoguProblemRepository();

  final ProblemRepository _repository;

  AsyncValue<List<Problem>> state = const AsyncInitial();
  String keyword = '';
  ProblemDifficulty? difficulty;
  String? tag;
  ProblemSortOption sortOption = ProblemSortOption.idAsc;

  Future<void> load() async {
    state = const AsyncLoading();
    notifyListeners();

    try {
      state = AsyncData(
        await _repository.fetchProblems(
          keyword: keyword,
          difficulty: difficulty,
          tag: tag,
          sortOption: sortOption,
        ),
      );
    } on Object catch (error) {
      state = AsyncError(error.toString());
    }

    notifyListeners();
  }

  Future<void> search(String value) async {
    keyword = value.trim();
    await load();
  }

  Future<void> filterByDifficulty(ProblemDifficulty? value) async {
    difficulty = value;
    await load();
  }

  Future<void> filterByTag(String? value) async {
    tag = value;
    await load();
  }

  Future<void> sortBy(ProblemSortOption value) async {
    sortOption = value;
    await load();
  }
}
