import '../../../core/network/api_client.dart';
import '../../../core/network/luogu_json.dart';
import '../domain/models/code_submission.dart';

class LuoguLanguageRepository {
  LuoguLanguageRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<SubmitLanguage>> fetchSubmitLanguages({
    required List<int> acceptedIds,
  }) async {
    try {
      final json = await _apiClient.getJson('/_lfe/config');
      final config = LuoguJson.mapAt(json, 'CodeLanguage');
      final languages = config.entries
          .where((entry) => entry.value is Map<String, Object?>)
          .map((entry) {
            final item = Map<String, Object?>.from(
              entry.value as Map<String, Object?>,
            );
            return _languageFromJson(item);
          })
          .where((language) => language.id > 0)
          .where((language) {
            return acceptedIds.isEmpty || acceptedIds.contains(language.id);
          })
          .toList();

      languages.sort((a, b) {
        if (acceptedIds.isEmpty) {
          return a.id.compareTo(b.id);
        }

        return acceptedIds.indexOf(a.id).compareTo(acceptedIds.indexOf(b.id));
      });
      if (languages.isNotEmpty) {
        return languages;
      }
    } on Object {
      // Keep submit usable when the config endpoint is blocked by CORS.
    }

    return _fallbackLanguages(acceptedIds);
  }

  SubmitLanguage _languageFromJson(Map<String, Object?> json) {
    final id = LuoguJson.intValue(json, const ['id', 'value']);
    final base = SubmitLanguages.fallbackById(id);
    final disabled = json['disabled'] == true;
    final name = LuoguJson.stringValue(
      json,
      const ['name'],
      fallback: base.name,
    );

    return SubmitLanguage(
      id: id,
      name: disabled ? '$name（不可用）' : name,
      type: LuoguJson.stringValue(json, const ['type'], fallback: base.type),
      highlightMode: LuoguJson.stringValue(
        json,
        const ['hljs', 'hljsMode', 'aceMode'],
        fallback: base.highlightMode,
      ),
      canO2: json['canO2'] == true,
      template: _templateFor(
        LuoguJson.stringValue(json, const ['type'], fallback: base.type),
        base.template,
      ),
    );
  }

  List<SubmitLanguage> _fallbackLanguages(List<int> acceptedIds) {
    if (acceptedIds.isEmpty) {
      return SubmitLanguages.values;
    }

    return acceptedIds.map(SubmitLanguages.fallbackById).toList();
  }

  String _templateFor(String type, String fallback) {
    if (fallback.isNotEmpty) {
      return fallback;
    }
    if (type.startsWith('Cpp')) {
      return SubmitLanguages.cpp17.template;
    }

    return switch (type) {
      'C' => '#include <stdio.h>\n\nint main(void) {\n    return 0;\n}\n',
      'Python3' || 'PyPy3' => SubmitLanguages.values[2].template,
      'Java8' || 'Java21' => SubmitLanguages.values[3].template,
      'Rust' => SubmitLanguages.values[4].template,
      'Go' => SubmitLanguages.values[5].template,
      _ => '',
    };
  }
}
