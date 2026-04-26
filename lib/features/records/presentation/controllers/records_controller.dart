import 'package:flutter/foundation.dart';

import '../../../../core/utils/async_value.dart';
import '../../data/luogu_records_repository.dart';
import '../../domain/models/submission_record.dart';
import '../../domain/repositories/records_repository.dart';

class RecordsController extends ChangeNotifier {
  RecordsController({
    RecordsRepository? repository,
  }) : _repository = repository ?? LuoguRecordsRepository();

  final RecordsRepository _repository;

  AsyncValue<List<SubmissionRecord>> state = const AsyncInitial();

  Future<void> load() async {
    state = const AsyncLoading();
    notifyListeners();

    try {
      state = AsyncData(await _repository.fetchRecords());
    } on Object catch (error) {
      state = AsyncError(error.toString());
    }

    notifyListeners();
  }
}
