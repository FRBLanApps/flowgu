import '../../../core/network/api_client.dart';
import '../../../core/network/luogu_json.dart';
import '../domain/models/code_submission.dart';
import '../domain/models/problem.dart';
import '../domain/repositories/submission_repository.dart';

class LuoguSubmissionRepository implements SubmissionRepository {
  LuoguSubmissionRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<CodeSubmissionResult> submit(CodeSubmissionRequest request) async {
    if (request.problem.source != ProblemSource.luogu) {
      return const CodeSubmissionResult(
        success: false,
        message: 'AtCoder 提交需要原站登录态，当前先保留跳转入口。',
      );
    }

    if (request.code.trim().isEmpty) {
      return const CodeSubmissionResult(
        success: false,
        message: '代码不能为空。',
      );
    }

    try {
      final csrfToken =
          await _apiClient.fetchCsrfToken('/problem/${request.problem.id}');
      final json = await _apiClient.postJson(
        '/fe/api/problem/submit/${request.problem.id}',
        query: {
          'contestId': request.contestId,
        },
        csrfToken: csrfToken,
        body: {
          'language': request.language.id,
          'code': request.code,
          'enableO2': request.enableO2,
          'o2': request.enableO2,
          if (request.captcha != null && request.captcha!.isNotEmpty)
            'captcha': request.captcha,
        },
      );
      final data = LuoguJson.unwrap(json);
      final recordId =
          LuoguJson.stringValue(data, const ['rid', 'recordId', 'id']);
      final message = LuoguJson.stringValue(
        data,
        const ['message', 'msg'],
        fallback: '提交已发送',
      );

      return CodeSubmissionResult(
        success: true,
        recordId: recordId.isEmpty ? null : recordId,
        message: message,
      );
    } on Object catch (error) {
      return CodeSubmissionResult(
        success: false,
        message: _friendlyMessage(error.toString()),
      );
    }
  }

  String _friendlyMessage(String raw) {
    if (raw.contains('auth/login') ||
        raw.contains('401') ||
        raw.contains('403')) {
      return '提交需要洛谷登录态。请先在“我的”页面登录洛谷账号后再提交。';
    }
    if (raw.contains('浏览器阻止')) {
      return '浏览器环境阻止了跨域提交。桌面端可直接提交，Web 端需要登录态和站点允许跨域。';
    }

    return raw.replaceFirst('Exception: ', '');
  }
}
