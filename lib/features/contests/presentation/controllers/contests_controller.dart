import 'package:flutter/foundation.dart';

import '../../../../core/utils/async_value.dart';
import '../../data/luogu_contest_repository.dart';
import '../../domain/models/contest.dart';
import '../../domain/repositories/contest_repository.dart';

class ContestsController extends ChangeNotifier {
  ContestsController({
    ContestRepository? repository,
  }) : _repository = repository ?? LuoguContestRepository();

  final ContestRepository _repository;

  AsyncValue<List<Contest>> official = const AsyncInitial();
  AsyncValue<List<Contest>> publicContests = const AsyncInitial();
  AsyncValue<List<Contest>> atcoder = const AsyncInitial();

  Future<void> load() async {
    official = const AsyncLoading();
    publicContests = const AsyncLoading();
    atcoder = const AsyncLoading();
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.fetchOfficialContests(),
        _repository.fetchPublicContests(),
        _repository.fetchAtCoderContests(),
      ]);
      official = AsyncData(results[0]);
      publicContests = AsyncData(results[1]);
      atcoder = AsyncData(results[2]);
    } on Object catch (error) {
      official = AsyncError(error.toString());
      publicContests = AsyncError(error.toString());
      atcoder = AsyncError(error.toString());
    }

    notifyListeners();
  }
}
