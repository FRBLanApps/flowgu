enum AppFlavor {
  mock,
  development,
  production,
}

class AppEnvironment {
  const AppEnvironment._();

  static const flavor = AppFlavor.production;
  static const luoguBaseUrl = 'https://www.luogu.com.cn';
  static const atcoderBaseUrl = 'https://atcoder.jp';
  static const apiBaseUrl = luoguBaseUrl;
  static const defaultUserAgent = 'Flowgu/0.1 Flutter';
}
