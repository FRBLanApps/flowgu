import 'package:flutter/foundation.dart';

import '../../../../core/utils/async_value.dart';
import '../../data/luogu_contest_repository.dart';
import '../../domain/models/contest.dart';
import '../../domain/repositories/contest_repository.dart';

class ContestDetailController extends ChangeNotifier {
  ContestDetailController({
    ContestRepository? repository,
  }) : _repository = repository ?? LuoguContestRepository();

  final ContestRepository _repository;

  AsyncValue<Contest> state = const AsyncInitial();

  Future<void> load(Contest contest) async {
    state = const AsyncLoading();
    notifyListeners();

    try {
      state = AsyncData(await _repository.fetchContestDetail(contest));
    } on Object catch (error) {
      state = AsyncError(error.toString());
    }

    notifyListeners();
  }
}
