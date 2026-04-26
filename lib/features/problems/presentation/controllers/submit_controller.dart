import 'package:flutter/foundation.dart';

import '../../../../core/utils/async_value.dart';
import '../../data/luogu_submission_repository.dart';
import '../../domain/models/code_submission.dart';
import '../../domain/repositories/submission_repository.dart';

class SubmitController extends ChangeNotifier {
  SubmitController({
    SubmissionRepository? repository,
  }) : _repository = repository ?? LuoguSubmissionRepository();

  final SubmissionRepository _repository;

  AsyncValue<CodeSubmissionResult> state = const AsyncInitial();

  Future<void> submit(CodeSubmissionRequest request) async {
    state = const AsyncLoading();
    notifyListeners();

    try {
      state = AsyncData(await _repository.submit(request));
    } on Object catch (error) {
      state = AsyncError(error.toString());
    }

    notifyListeners();
  }
}
