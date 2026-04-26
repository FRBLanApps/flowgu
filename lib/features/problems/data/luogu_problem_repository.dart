import '../../../core/network/api_client.dart';
import '../../../core/network/luogu_json.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/models/problem.dart';
import '../domain/repositories/problem_repository.dart';
import 'offline_problem_catalog.dart';
import 'luogu_tag_catalog.dart';

class LuoguProblemRepository implements ProblemRepository {
  LuoguProblemRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<List<Problem>> fetchProblems({
    String keyword = '',
    ProblemDifficulty? difficulty,
    String? tag,
    ProblemSortOption sortOption = ProblemSortOption.idAsc,
  }) async {
    try {
      final json = await _apiClient.getJson(
        '/problem/list',
        responseType: LuoguResponseType.lentille,
        query: {
          'type': 'P',
          'page': '1',
          'keyword': keyword,
          if (difficulty != null) 'difficulty': _difficultyToLuogu(difficulty),
          if (tag != null && tag.isNotEmpty) 'tag': _tagToLuogu(tag),
        },
      );
      final data = LuoguJson.unwrap(json);
      final problems = _extractProblems(data)
          .whereType<Map>()
          .map(
            (problem) => _problemFromJson(Map<String, Object?>.from(problem)),
          )
          .toList(growable: false);

      final filtered = _filterAndSortProblems(
        problems,
        tag: tag,
        sortOption: sortOption,
      );

      if (filtered.isNotEmpty) {
        return filtered;
      }
    } on Object {
      // Flutter Web cannot read Luogu cross-origin responses without server CORS.
      // Keep the problem list usable by falling back to a small verified catalog.
    }

    return OfflineProblemCatalog.search(
      keyword: keyword,
      difficulty: difficulty,
      tag: tag,
      sortOption: sortOption,
    );
  }

  @override
  Future<Problem> fetchProblemDetail(Problem problem) async {
    if (problem.source != ProblemSource.luogu) {
      return problem;
    }

    try {
      final json = await _apiClient.getJson(
        '/problem/${problem.id}',
        responseType: LuoguResponseType.lentille,
      );
      final data = LuoguJson.unwrap(json);
      final detail = LuoguJson.mapAt(data, 'problem');
      if (detail.isEmpty) {
        throw const AppException('题目详情为空');
      }

      return _problemFromJson(detail);
    } on Object {
      return OfflineProblemCatalog.enrich(problem);
    }
  }

  List<Object?> _extractProblems(Map<String, Object?> data) {
    final direct = LuoguJson.listAt(data, const ['problems']);
    if (direct.isNotEmpty) {
      return direct;
    }

    final result = LuoguJson.listAt(data, const ['problems', 'result']);
    if (result.isNotEmpty) {
      return result;
    }

    return LuoguJson.listAt(data, const ['result']);
  }

  Problem _problemFromJson(Map<String, Object?> json) {
    final accepted = LuoguJson.doubleValue(
      json,
      const ['accepted', 'acceptedCount', 'totalAccepted'],
    );
    final submitted = LuoguJson.doubleValue(
      json,
      const ['submitted', 'totalSubmit', 'submit'],
    );
    final acceptRate = submitted <= 0 ? 0.0 : accepted / submitted * 100;
    final difficulty =
        LuoguJson.intValue(json, const ['difficulty'], fallback: 1);
    final content = _contentFromJson(json);
    final pid =
        LuoguJson.stringValue(json, const ['pid', 'id'], fallback: 'P?');
    final title = LuoguJson.stringValue(
      json,
      const ['title', 'name'],
      fallback: LuoguJson.stringValue(
        content,
        const ['name', 'title'],
        fallback: '未命名题目',
      ),
    );

    return Problem(
      id: pid,
      title: title,
      difficulty: _difficultyFromLuogu(difficulty),
      acceptRate: acceptRate,
      isAccepted: _isAccepted(json),
      tags: _tagsFromJson(json),
      url: 'https://www.luogu.com.cn/problem/$pid',
      background: LuoguJson.stringValue(content, const ['background']),
      description: LuoguJson.stringValue(
        content,
        const ['description'],
        fallback: '题面内容可在详情页打开原站查看；列表数据来自洛谷公开题库。',
      ),
      inputFormat: LuoguJson.stringValue(content, const ['formatI']),
      outputFormat: LuoguJson.stringValue(content, const ['formatO']),
      hint: LuoguJson.stringValue(content, const ['hint']),
      samples: _samplesFromJson(json),
      timeLimit: _limitLabel(json, 'time', 'ms'),
      memoryLimit: _limitLabel(json, 'memory', 'KB'),
      acceptLanguages: _acceptLanguagesFromJson(json),
    );
  }

  Map<String, Object?> _contentFromJson(Map<String, Object?> json) {
    final content = LuoguJson.mapAt(json, 'content');
    if (content.isNotEmpty) {
      return content;
    }

    return LuoguJson.mapAt(json, 'contenu');
  }

  List<ProblemSample> _samplesFromJson(Map<String, Object?> json) {
    final samples = json['samples'];
    if (samples is! List) {
      return const [];
    }

    return samples.whereType<List>().map((sample) {
      final input = sample.isNotEmpty ? '${sample[0]}'.trimRight() : '';
      final output = sample.length > 1 ? '${sample[1]}'.trimRight() : '';
      return ProblemSample(input: input, output: output);
    }).toList(growable: false);
  }

  List<int> _acceptLanguagesFromJson(Map<String, Object?> json) {
    final rawLanguages = json['acceptLanguages'];
    if (rawLanguages is! List) {
      return const [];
    }

    return rawLanguages.whereType<num>().map((item) => item.toInt()).toList();
  }

  String? _limitLabel(Map<String, Object?> json, String key, String unit) {
    final limits = LuoguJson.mapAt(json, 'limits');
    final values = limits[key];
    if (values is List && values.isNotEmpty) {
      return '${values.first}$unit';
    }
    return null;
  }

  List<Problem> _filterAndSortProblems(
    List<Problem> problems, {
    required String? tag,
    required ProblemSortOption sortOption,
  }) {
    final selectedTag = LuoguTagCatalog.findById(tag);
    final normalizedTag =
        selectedTag?.name.trim().toLowerCase() ?? tag?.trim().toLowerCase();
    final filtered = problems.where((problem) {
      if (normalizedTag == null || normalizedTag.isEmpty) {
        return true;
      }
      return problem.tags.any((item) => item.toLowerCase() == normalizedTag);
    }).toList();

    switch (sortOption) {
      case ProblemSortOption.idAsc:
        filtered.sort((a, b) => a.id.compareTo(b.id));
      case ProblemSortOption.idDesc:
        filtered.sort((a, b) => b.id.compareTo(a.id));
      case ProblemSortOption.difficultyAsc:
        filtered
            .sort((a, b) => a.difficulty.index.compareTo(b.difficulty.index));
      case ProblemSortOption.difficultyDesc:
        filtered
            .sort((a, b) => b.difficulty.index.compareTo(a.difficulty.index));
      case ProblemSortOption.acceptRateDesc:
        filtered.sort((a, b) => b.acceptRate.compareTo(a.acceptRate));
      case ProblemSortOption.acceptRateAsc:
        filtered.sort((a, b) => a.acceptRate.compareTo(b.acceptRate));
    }

    return filtered;
  }

  List<String> _tagsFromJson(Map<String, Object?> json) {
    final rawTags = json['tags'];
    if (rawTags is! List) {
      return const [];
    }

    return rawTags
        .map((tag) => LuoguTagCatalog.nameOf('$tag'))
        .where((tag) => tag != '全部标签')
        .toList();
  }

  bool _isAccepted(Map<String, Object?> json) {
    final status = json['status'];
    if (status is int) {
      return status == 12 || status == 1;
    }
    if (status is Map<String, Object?>) {
      final accepted = status['accepted'] ?? status['score'];
      return accepted == true || accepted == 100;
    }

    return false;
  }

  ProblemDifficulty _difficultyFromLuogu(int difficulty) {
    return switch (difficulty) {
      0 => ProblemDifficulty.unrated,
      1 => ProblemDifficulty.beginner,
      2 => ProblemDifficulty.easy,
      3 => ProblemDifficulty.normal,
      4 => ProblemDifficulty.medium,
      5 => ProblemDifficulty.hard,
      6 => ProblemDifficulty.provincial,
      _ => ProblemDifficulty.noi,
    };
  }

  String _difficultyToLuogu(ProblemDifficulty difficulty) {
    return switch (difficulty) {
      ProblemDifficulty.unrated => '0',
      ProblemDifficulty.beginner => '1',
      ProblemDifficulty.easy => '2',
      ProblemDifficulty.normal => '3',
      ProblemDifficulty.medium => '4',
      ProblemDifficulty.hard => '5',
      ProblemDifficulty.provincial => '6',
      ProblemDifficulty.noi => '7',
    };
  }

  String _tagToLuogu(String tag) {
    return tag;
  }
}
