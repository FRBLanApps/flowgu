import 'package:flutter/foundation.dart';

import '../../../../core/utils/async_value.dart';
import '../../data/luogu_dashboard_repository.dart';
import '../../domain/models/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    DashboardRepository? repository,
  }) : _repository = repository ?? LuoguDashboardRepository();

  final DashboardRepository _repository;

  AsyncValue<DashboardSummary> state = const AsyncInitial();

  Future<void> load() async {
    state = const AsyncLoading();
    notifyListeners();

    try {
      state = AsyncData(await _repository.fetchSummary());
    } on Object catch (error) {
      state = AsyncError(error.toString());
    }

    notifyListeners();
  }
}
