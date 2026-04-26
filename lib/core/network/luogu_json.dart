class LuoguJson {
  const LuoguJson._();

  static Map<String, Object?> unwrap(Map<String, Object?> json) {
    final data = json['data'];
    if (data is Map<String, Object?>) {
      return data;
    }

    final currentData = json['currentData'];
    if (currentData is Map<String, Object?>) {
      return currentData;
    }

    return json;
  }

  static List<Object?> listAt(
    Map<String, Object?> json,
    List<String> path,
  ) {
    Object? cursor = json;
    for (final segment in path) {
      if (cursor is Map<String, Object?>) {
        cursor = cursor[segment];
      } else {
        return const [];
      }
    }

    return cursor is List<Object?> ? cursor : const [];
  }

  static Map<String, Object?> mapAt(
    Map<String, Object?> json,
    String key,
  ) {
    final value = json[key];
    return value is Map<String, Object?> ? value : const {};
  }

  static String stringValue(
    Map<String, Object?> json,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
      if (value is num) {
        return value.toString();
      }
    }

    return fallback;
  }

  static int intValue(
    Map<String, Object?> json,
    List<String> keys, {
    int fallback = 0,
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }

    return fallback;
  }

  static double doubleValue(
    Map<String, Object?> json,
    List<String> keys, {
    double fallback = 0,
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }

    return fallback;
  }
}
