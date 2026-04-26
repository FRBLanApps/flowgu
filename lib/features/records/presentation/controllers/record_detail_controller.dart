import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/utils/async_value.dart';
import '../../data/luogu_records_repository.dart';
import '../../domain/models/submission_record.dart';
import '../../domain/repositories/records_repository.dart';

class RecordDetailController extends ChangeNotifier {
  RecordDetailController({
    RecordsRepository? repository,
  }) : _repository = repository ?? LuoguRecordsRepository();

  final RecordsRepository _repository;

  AsyncValue<SubmissionRecord> state = const AsyncInitial();
  int retryCount = 0;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load(
    String recordId, {
    bool retryOnFailure = false,
  }) async {
    state = const AsyncLoading();
    _safeNotify();

    final startedAt = DateTime.now();
    retryCount = 0;

    while (true) {
      try {
        final record = await _repository.fetchRecordDetail(recordId);
        state = AsyncData(record);
        _safeNotify();

        if (!retryOnFailure ||
            record.isFinal ||
            _hasCompileErrorOutput(record) ||
            DateTime.now().difference(startedAt).inSeconds >= 30) {
          return;
        }
      } on Object catch (error) {
        if (!retryOnFailure ||
            DateTime.now().difference(startedAt).inSeconds >= 30) {
          state = AsyncError(error.toString());
          _safeNotify();
          return;
        }
      }

      retryCount += 1;
      _safeNotify();
      await Future<void>.delayed(const Duration(seconds: 5));
    }
  }

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  bool _hasCompileErrorOutput(SubmissionRecord record) {
    return record.compileMessage != null &&
        record.compileMessage!.trim().isNotEmpty;
  }
}
