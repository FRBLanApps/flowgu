enum AccountPlatform {
  luogu,
  atcoder,
}

class LinkedAccount {
  const LinkedAccount({
    required this.platform,
    required this.username,
    required this.isConnected,
    this.detail,
  });

  final AccountPlatform platform;
  final String username;
  final bool isConnected;
  final String? detail;

  String get platformLabel {
    return switch (platform) {
      AccountPlatform.luogu => '洛谷',
      AccountPlatform.atcoder => 'AtCoder',
    };
  }
}
