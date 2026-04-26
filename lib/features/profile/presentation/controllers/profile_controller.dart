import 'package:flutter/foundation.dart';

import '../../../../core/utils/async_value.dart';
import '../../data/luogu_profile_repository.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileController extends ChangeNotifier {
  ProfileController({
    ProfileRepository? repository,
  }) : _repository = repository ?? LuoguProfileRepository();

  final ProfileRepository _repository;

  AsyncValue<UserProfile> state = const AsyncInitial();

  Future<void> load() async {
    state = const AsyncLoading();
    notifyListeners();

    try {
      state = AsyncData(await _repository.fetchCurrentUser());
    } on Object catch (error) {
      state = AsyncError(error.toString());
    }

    notifyListeners();
  }
}
