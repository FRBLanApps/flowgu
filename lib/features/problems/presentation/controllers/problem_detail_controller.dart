import 'package:flutter/foundation.dart';

import '../../../../core/utils/async_value.dart';
import '../../data/luogu_problem_repository.dart';
import '../../domain/models/problem.dart';
import '../../domain/repositories/problem_repository.dart';

class ProblemDetailController extends ChangeNotifier {
  ProblemDetailController({
    ProblemRepository? repository,
  }) : _repository = repository ?? LuoguProblemRepository();

  final ProblemRepository _repository;

  AsyncValue<Problem> state = const AsyncInitial();

  Future<void> load(Problem problem) async {
    state = const AsyncLoading();
    notifyListeners();

    try {
      state = AsyncData(await _repository.fetchProblemDetail(problem));
    } on Object catch (error) {
      state = AsyncError(error.toString());
    }

    notifyListeners();
  }
}
