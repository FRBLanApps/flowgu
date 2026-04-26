import '../models/account_auth.dart';

abstract class AccountAuthRepository {
  Future<AccountAuthResult> connect(AccountAuthRequest request);
  Future<void> disconnect();
}
