import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppI18n {
  const AppI18n(this.locale, this._messages);

  final Locale locale;
  final Map<String, String> _messages;

  static const supportedLocales = [
    Locale('zh', 'CN'),
    Locale('en', 'US'),
  ];

  static const localizationsDelegates = [
    AppI18nDelegate(),
  ];

  static AppI18n of(BuildContext context) {
    return Localizations.of<AppI18n>(context, AppI18n)!;
  }

  String t(String key, {Map<String, Object?> args = const {}}) {
    var text = _messages[key] ?? key;
    for (final entry in args.entries) {
      text = text.replaceAll('{${entry.key}}', '${entry.value}');
    }
    return text;
  }
}

extension AppI18nBuildContext on BuildContext {
  String t(String key, {Map<String, Object?> args = const {}}) {
    return AppI18n.of(this).t(key, args: args);
  }
}

class AppI18nDelegate extends LocalizationsDelegate<AppI18n> {
  const AppI18nDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppI18n.supportedLocales.any(
      (item) => item.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppI18n> load(Locale locale) async {
    final normalized = _normalize(locale);
    final content = await rootBundle.loadString('assets/lang/$normalized.json');
    final decoded = jsonDecode(content);
    final messages = (decoded as Map).map(
      (key, value) => MapEntry('$key', '$value'),
    );
    return AppI18n(locale, messages);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppI18n> old) => false;

  String _normalize(Locale locale) {
    if (locale.languageCode == 'zh') {
      return 'zh_CN';
    }
    return 'en_US';
  }
}
