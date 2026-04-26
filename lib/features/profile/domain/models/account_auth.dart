import 'linked_account.dart';

enum AccountLoginMode {
  password,
  cookie,
  publicProfile,
}

class AccountAuthRequest {
  const AccountAuthRequest({
    required this.platform,
    required this.mode,
    this.username = '',
    this.password = '',
    this.cookie = '',
    this.captcha = '',
  });

  final AccountPlatform platform;
  final AccountLoginMode mode;
  final String username;
  final String password;
  final String cookie;
  final String captcha;
}

class AccountAuthResult {
  const AccountAuthResult({
    required this.account,
    required this.message,
  });

  final LinkedAccount account;
  final String message;
}
