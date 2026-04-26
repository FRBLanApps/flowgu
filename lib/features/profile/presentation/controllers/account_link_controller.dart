import 'package:flutter/foundation.dart';

import '../../../../core/utils/async_value.dart';
import '../../data/account_auth_repository_impl.dart';
import '../../domain/models/account_auth.dart';
import '../../domain/models/linked_account.dart';
import '../../domain/repositories/account_auth_repository.dart';

class AccountLinkController extends ChangeNotifier {
  AccountLinkController({
    AccountAuthRepository? repository,
  }) : _repository = repository ?? AccountAuthRepositoryImpl();

  final AccountAuthRepository _repository;
  final Map<AccountPlatform, LinkedAccount> _accounts = {};

  AsyncValue<AccountAuthResult> state = const AsyncInitial();

  List<LinkedAccount> get accounts {
    return AccountPlatform.values.map((platform) {
      return _accounts[platform] ??
          LinkedAccount(
            platform: platform,
            username: '',
            isConnected: false,
          );
    }).toList(growable: false);
  }

  Future<void> connect(AccountAuthRequest request) async {
    state = const AsyncLoading();
    notifyListeners();

    try {
      final result = await _repository.connect(request);
      _accounts[result.account.platform] = result.account;
      state = AsyncData(result);
    } on Object catch (error) {
      state = AsyncError(error.toString());
    }

    notifyListeners();
  }

  void applyAccount(LinkedAccount account) {
    _accounts[account.platform] = account;
    state = AsyncData(
      AccountAuthResult(
        account: account,
        message: 'auth.accountConnected',
      ),
    );
    notifyListeners();
  }

  Future<void> disconnect(AccountPlatform platform) async {
    if (platform == AccountPlatform.luogu) {
      await _repository.disconnect();
    }
    _accounts.remove(platform);
    state = const AsyncInitial();
    notifyListeners();
  }
}
