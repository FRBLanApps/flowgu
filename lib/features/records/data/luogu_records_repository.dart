import '../../../core/network/api_client.dart';
import '../../../core/network/app_session.dart';
import '../../../core/network/luogu_json.dart';
import '../domain/models/submission_record.dart';
import '../domain/repositories/records_repository.dart';

class LuoguRecordsRepository implements RecordsRepository {
  LuoguRecordsRepository({
    ApiClient? apiClient,
    this.userId,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  final String? userId;

  @override
  Future<List<SubmissionRecord>> fetchRecords() async {
    final json = await _apiClient.getJson(
      '/record/list',
      responseType: LuoguResponseType.data,
      query: {
        'page': '1',
        if ((userId ?? AppSession.luoguUid) != null)
          'user': userId ?? AppSession.luoguUid,
      },
    );
    final data = LuoguJson.unwrap(json);
    final records = _extractRecords(data);

    return records
        .whereType<Map>()
        .map((record) => _recordFromJson(Map<String, Object?>.from(record)))
        .toList(growable: false);
  }

  @override
  Future<SubmissionRecord> fetchRecordDetail(String recordId) async {
    final json = await _apiClient.getJson(
      '/record/$recordId',
      responseType: LuoguResponseType.data,
    );
    final data = LuoguJson.unwrap(json);
    final record = LuoguJson.mapAt(data, 'record').isEmpty
        ? data
        : LuoguJson.mapAt(data, 'record');

    return _recordFromJson(record);
  }

  List<Object?> _extractRecords(Map<String, Object?> data) {
    final records = LuoguJson.listAt(data, const ['records']);
    if (records.isNotEmpty) {
      return records;
    }

    final result = LuoguJson.listAt(data, const ['records', 'result']);
    if (result.isNotEmpty) {
      return result;
    }

    return LuoguJson.listAt(data, const ['result']);
  }

  SubmissionRecord _recordFromJson(Map<String, Object?> json) {
    final problem = LuoguJson.mapAt(json, 'problem');
    final user = LuoguJson.mapAt(json, 'user');
    final status = LuoguJson.intValue(json, const ['status'], fallback: 0);
    final compileMessage = _compileMessageFromJson(json);

    return SubmissionRecord(
      id: LuoguJson.stringValue(json, const ['id', 'rid'], fallback: '0'),
      problemId:
          LuoguJson.stringValue(problem, const ['pid', 'id'], fallback: '?'),
      problemTitle: LuoguJson.stringValue(
        problem,
        const ['title', 'name'],
        fallback: '未知题目',
      ),
      userName: LuoguJson.stringValue(
        user,
        const ['name', 'username'],
        fallback: '未知用户',
      ),
      language: LuoguJson.stringValue(
        json,
        const ['language', 'lang'],
        fallback: '未知语言',
      ),
      duration: '${LuoguJson.intValue(json, const ['time'], fallback: 0)}ms',
      memory: '${LuoguJson.intValue(json, const ['memory'], fallback: 0)}KB',
      submittedAt: _formatSubmittedAt(
        LuoguJson.intValue(
          json,
          const ['submitTime', 'submittedAt'],
          fallback: 0,
        ),
      ),
      result: _resultFromStatus(status, compileMessage: compileMessage),
      score: _scoreFromJson(json),
      statusCode: status,
      compileMessage: compileMessage,
      sourceCode: LuoguJson.stringValue(json, const ['sourceCode', 'code']),
      subtasks: _subtasksFromJson(json),
    );
  }

  int? _scoreFromJson(Map<String, Object?> json) {
    final score = json['score'];
    if (score is num) {
      return score.toInt();
    }

    final detail = LuoguJson.mapAt(json, 'detail');
    final judgeResult = LuoguJson.mapAt(detail, 'judgeResult');
    final judgeScore = judgeResult['score'];
    return judgeScore is num ? judgeScore.toInt() : null;
  }

  String? _compileMessageFromJson(Map<String, Object?> json) {
    final detail = LuoguJson.mapAt(json, 'detail');
    final compileResult = LuoguJson.mapAt(detail, 'compileResult');
    return LuoguJson.stringValue(compileResult, const ['message']);
  }

  List<SubmissionSubtask> _subtasksFromJson(Map<String, Object?> json) {
    final detail = LuoguJson.mapAt(json, 'detail');
    final judgeResult = LuoguJson.mapAt(detail, 'judgeResult');
    final rawSubtasks = judgeResult['subtasks'];
    final subtasks = _objectList(rawSubtasks);

    return subtasks.map((subtask) {
      final status = LuoguJson.intValue(subtask, const ['status']);
      return SubmissionSubtask(
        id: LuoguJson.intValue(subtask, const ['id']),
        score: LuoguJson.intValue(subtask, const ['score']),
        status: _resultFromStatus(status),
        time: LuoguJson.intValue(subtask, const ['time']),
        memory: LuoguJson.intValue(subtask, const ['memory']),
        testCases: _testCasesFromJson(subtask),
      );
    }).toList(growable: false);
  }

  List<SubmissionTestCase> _testCasesFromJson(Map<String, Object?> subtask) {
    return _objectList(subtask['testCases']).map((testCase) {
      final status = LuoguJson.intValue(testCase, const ['status']);
      final description = testCase['description'];

      return SubmissionTestCase(
        id: LuoguJson.intValue(testCase, const ['id']),
        status: _resultFromStatus(status),
        time: LuoguJson.intValue(testCase, const ['time']),
        memory: LuoguJson.intValue(testCase, const ['memory']),
        score: LuoguJson.intValue(testCase, const ['score']),
        description: description is String ? description : null,
        signal: _nullableInt(testCase['signal']),
        exitCode: _nullableInt(testCase['exitCode']),
      );
    }).toList(growable: false);
  }

  List<Map<String, Object?>> _objectList(Object? value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, Object?>.from(item))
          .toList(growable: false);
    }
    if (value is Map) {
      return value.values
          .whereType<Map>()
          .map((item) => Map<String, Object?>.from(item))
          .toList(growable: false);
    }

    return const [];
  }

  int? _nullableInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }

    return null;
  }

  SubmissionResult _resultFromStatus(int status, {String? compileMessage}) {
    if (compileMessage != null && compileMessage.trim().isNotEmpty) {
      return SubmissionResult.compileError;
    }

    return switch (status) {
      0 => SubmissionResult.waiting,
      1 => SubmissionResult.judging,
      2 => SubmissionResult.compiling,
      3 => SubmissionResult.compileError,
      12 => SubmissionResult.accepted,
      5 => SubmissionResult.timeLimitExceeded,
      7 => SubmissionResult.runtimeError,
      11 => SubmissionResult.wrongAnswer,
      _ => SubmissionResult.wrongAnswer,
    };
  }

  String _formatSubmittedAt(int timestamp) {
    if (timestamp <= 0) {
      return '时间未知';
    }

    final seconds = DateTime.now().millisecondsSinceEpoch ~/ 1000 - timestamp;
    if (seconds < 60) {
      return '刚刚';
    }
    if (seconds < 3600) {
      return '${seconds ~/ 60} 分钟前';
    }
    if (seconds < 86400) {
      return '${seconds ~/ 3600} 小时前';
    }

    return '${seconds ~/ 86400} 天前';
  }
}
