import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSession {
  const AppSession._();

  static const _cookieStorageKey = 'flowgu.luogu.cookie';
  static const _legacyLoginClearedKey =
      'flowgu.migrations.clearedLegacyLogin.v1';

  static final Map<String, String> _cookies = {};
  static final ValueNotifier<int> listenable = ValueNotifier<int>(0);

  static bool get hasLuoguSession {
    return _cookies['_uid'] != null && _cookies['__client_id'] != null;
  }

  static String? get luoguUid => _cookies['_uid'];

  static String? get cookieHeader {
    if (_cookies.isEmpty) {
      return null;
    }

    return _cookies.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('; ');
  }

  static Future<void> restore() async {
    final preferences = await SharedPreferences.getInstance();
    final storedCookie = preferences.getString(_cookieStorageKey);
    if (storedCookie == null || storedCookie.isEmpty) {
      return;
    }
    setCookieHeader(storedCookie, persist: false);
  }

  static Future<void> clearLegacySavedLoginOnce() async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(_legacyLoginClearedKey) ?? false) {
      return;
    }
    _cookies.clear();
    await preferences.remove(_cookieStorageKey);
    await preferences.setBool(_legacyLoginClearedKey, true);
    _notify();
  }

  static Future<void> save() async {
    final header = cookieHeader;
    final preferences = await SharedPreferences.getInstance();
    if (header == null || header.isEmpty) {
      await preferences.remove(_cookieStorageKey);
      return;
    }
    await preferences.setString(_cookieStorageKey, header);
  }

  static void setCookieHeader(String cookieHeader, {bool persist = true}) {
    var changed = false;
    for (final chunk in cookieHeader.split(';')) {
      final separator = chunk.indexOf('=');
      if (separator <= 0) {
        continue;
      }
      final key = chunk.substring(0, separator).trim();
      final value = chunk.substring(separator + 1).trim();
      if (key.isNotEmpty && value.isNotEmpty) {
        _cookies[key] = value;
        changed = true;
      }
    }
    if (changed) {
      _notify();
      if (persist) {
        unawaited(save());
      }
    }
  }

  static void absorbSetCookieHeader(
    String? setCookieHeader, {
    bool persist = true,
  }) {
    if (setCookieHeader == null || setCookieHeader.isEmpty) {
      return;
    }

    var changed = false;
    final cookiePattern = RegExp(r'(^|,\s*)([^,;=\s]+)=([^;,\s]*)');
    for (final match in cookiePattern.allMatches(setCookieHeader)) {
      final key = match.group(2);
      final value = match.group(3);
      if (key != null && value != null && key.isNotEmpty && value.isNotEmpty) {
        _cookies[key] = value;
        changed = true;
      }
    }
    if (changed) {
      _notify();
      if (persist) {
        unawaited(save());
      }
    }
  }

  static Future<void> clear() async {
    _cookies.clear();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_cookieStorageKey);
    _notify();
  }

  static void _notify() {
    listenable.value += 1;
  }
}
