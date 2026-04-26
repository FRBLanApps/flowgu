import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_card_style.dart';
import 'app_corner_radius.dart';
import 'app_visual_effect.dart';

class AppThemeController extends ChangeNotifier {
  AppThemeController._();

  static final AppThemeController instance = AppThemeController._();

  static const _themeModeKey = 'flowgu.settings.themeMode';
  static const _localeKey = 'flowgu.settings.locale';
  static const _seedColorKey = 'flowgu.settings.seedColor';
  static const _accentColorKey = 'flowgu.settings.accentColor';
  static const _visualEffectKey = 'flowgu.settings.visualEffect';
  static const _cardStyleKey = 'flowgu.settings.cardStyle';
  static const _cornerRadiusKey = 'flowgu.settings.cornerRadius';
  static const _customBackgroundUrlKey = 'flowgu.settings.customBackgroundUrl';
  static const _autoOpenRecordKey = 'flowgu.settings.autoOpenRecord';
  static const _recordRetryKey = 'flowgu.settings.recordRetry';
  static const _syntaxHighlightKey = 'flowgu.settings.syntaxHighlight';
  static const _latexAccentKey = 'flowgu.settings.latexAccent';
  static const _defaultO2Key = 'flowgu.settings.defaultO2';

  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('zh', 'CN');
  Color _seedColor = const Color(0xFF2F80ED);
  Color _accentColor = const Color(0xFF66CCFF);
  AppVisualEffect _visualEffect = AppVisualEffect.aurora;
  AppCardStyle _cardStyle = AppCardStyle.frosted;
  AppCornerRadius _cornerRadius = AppCornerRadius.rounded;
  String? _customBackgroundUrl;
  bool _autoOpenRecord = true;
  bool _recordRetry = true;
  bool _syntaxHighlight = true;
  bool _latexAccent = true;
  bool _defaultO2 = false;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  Color get seedColor => _seedColor;
  Color get accentColor => _accentColor;
  AppVisualEffect get visualEffect => _visualEffect;
  AppCardStyle get cardStyle => _cardStyle;
  AppCornerRadius get cornerRadius => _cornerRadius;
  String? get customBackgroundUrl => _customBackgroundUrl;
  bool get autoOpenRecord => _autoOpenRecord;
  bool get recordRetry => _recordRetry;
  bool get syntaxHighlight => _syntaxHighlight;
  bool get latexAccent => _latexAccent;
  bool get defaultO2 => _defaultO2;

  Future<void> restore() async {
    final preferences = await SharedPreferences.getInstance();
    _themeMode = _enumByName(
      ThemeMode.values,
      preferences.getString(_themeModeKey),
      _themeMode,
    );
    _locale = _localeFromTag(preferences.getString(_localeKey)) ?? _locale;
    _seedColor =
        Color(preferences.getInt(_seedColorKey) ?? _seedColor.toARGB32());
    _accentColor =
        Color(preferences.getInt(_accentColorKey) ?? _accentColor.toARGB32());
    _visualEffect = _enumByName(
      AppVisualEffect.values,
      preferences.getString(_visualEffectKey),
      _visualEffect,
    );
    _cardStyle = _enumByName(
      AppCardStyle.values,
      preferences.getString(_cardStyleKey),
      _cardStyle,
    );
    _cornerRadius = _enumByName(
      AppCornerRadius.values,
      preferences.getString(_cornerRadiusKey),
      _cornerRadius,
    );
    _customBackgroundUrl =
        _normalizeOptional(preferences.getString(_customBackgroundUrlKey));
    _autoOpenRecord =
        preferences.getBool(_autoOpenRecordKey) ?? _autoOpenRecord;
    _recordRetry = preferences.getBool(_recordRetryKey) ?? _recordRetry;
    _syntaxHighlight =
        preferences.getBool(_syntaxHighlightKey) ?? _syntaxHighlight;
    _latexAccent = preferences.getBool(_latexAccentKey) ?? _latexAccent;
    _defaultO2 = preferences.getBool(_defaultO2Key) ?? _defaultO2;
    notifyListeners();
  }

  Future<void> save() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeModeKey, _themeMode.name);
    await preferences.setString(_localeKey, _localeTag(_locale));
    await preferences.setInt(_seedColorKey, _seedColor.toARGB32());
    await preferences.setInt(_accentColorKey, _accentColor.toARGB32());
    await preferences.setString(_visualEffectKey, _visualEffect.name);
    await preferences.setString(_cardStyleKey, _cardStyle.name);
    await preferences.setString(_cornerRadiusKey, _cornerRadius.name);
    final customBackgroundUrl = _customBackgroundUrl;
    if (customBackgroundUrl == null || customBackgroundUrl.isEmpty) {
      await preferences.remove(_customBackgroundUrlKey);
    } else {
      await preferences.setString(_customBackgroundUrlKey, customBackgroundUrl);
    }
    await preferences.setBool(_autoOpenRecordKey, _autoOpenRecord);
    await preferences.setBool(_recordRetryKey, _recordRetry);
    await preferences.setBool(_syntaxHighlightKey, _syntaxHighlight);
    await preferences.setBool(_latexAccentKey, _latexAccent);
    await preferences.setBool(_defaultO2Key, _defaultO2);
  }

  void setThemeMode(ThemeMode value) {
    if (_themeMode == value) return;
    _themeMode = value;
    _commit();
  }

  void setLocale(Locale value) {
    if (_locale == value) return;
    _locale = value;
    _commit();
  }

  void setSeedColor(Color value) {
    if (_seedColor == value) return;
    _seedColor = value;
    _commit();
  }

  void setAccentColor(Color value) {
    if (_accentColor == value) return;
    _accentColor = value;
    _commit();
  }

  void setVisualEffect(AppVisualEffect value) {
    if (_visualEffect == value) return;
    _visualEffect = value;
    _commit();
  }

  void setCardStyle(AppCardStyle value) {
    if (_cardStyle == value) return;
    _cardStyle = value;
    _commit();
  }

  void setCornerRadius(AppCornerRadius value) {
    if (_cornerRadius == value) return;
    _cornerRadius = value;
    _commit();
  }

  void setCustomBackgroundUrl(String? value) {
    final next = _normalizeOptional(value);
    if (_customBackgroundUrl == next) return;
    _customBackgroundUrl = next;
    _commit();
  }

  void setAutoOpenRecord(bool value) {
    if (_autoOpenRecord == value) return;
    _autoOpenRecord = value;
    _commit();
  }

  void setRecordRetry(bool value) {
    if (_recordRetry == value) return;
    _recordRetry = value;
    _commit();
  }

  void setSyntaxHighlight(bool value) {
    if (_syntaxHighlight == value) return;
    _syntaxHighlight = value;
    _commit();
  }

  void setLatexAccent(bool value) {
    if (_latexAccent == value) return;
    _latexAccent = value;
    _commit();
  }

  void setDefaultO2(bool value) {
    if (_defaultO2 == value) return;
    _defaultO2 = value;
    _commit();
  }

  void _commit() {
    notifyListeners();
    unawaited(save());
  }

  static T _enumByName<T extends Enum>(
    List<T> values,
    String? name,
    T fallback,
  ) {
    if (name == null) {
      return fallback;
    }
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    return fallback;
  }

  static Locale? _localeFromTag(String? tag) {
    final normalized = _normalizeOptional(tag);
    if (normalized == null) {
      return null;
    }
    final parts = normalized.split(RegExp('[-_]'));
    if (parts.length == 1) {
      return Locale(parts.first);
    }
    return Locale(parts.first, parts[1]);
  }

  static String _localeTag(Locale locale) {
    final countryCode = locale.countryCode;
    if (countryCode == null || countryCode.isEmpty) {
      return locale.languageCode;
    }
    return '${locale.languageCode}_$countryCode';
  }

  static String? _normalizeOptional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
