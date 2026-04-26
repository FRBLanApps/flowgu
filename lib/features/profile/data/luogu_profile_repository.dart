import '../../../core/network/api_client.dart';
import '../../../core/network/app_session.dart';
import '../../../core/network/luogu_json.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/models/user_profile.dart';
import '../domain/repositories/profile_repository.dart';

class LuoguProfileRepository implements ProfileRepository {
  LuoguProfileRepository({
    ApiClient? apiClient,
    this.uid = '1',
    this.preferSession = true,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  final String uid;
  final bool preferSession;

  @override
  Future<UserProfile> fetchCurrentUser() async {
    if (preferSession && !AppSession.hasLuoguSession) {
      return _guestProfile();
    }

    final targetUid = preferSession ? AppSession.luoguUid ?? uid : uid;
    late final Map<String, Object?> json;
    try {
      json = await _apiClient.getJson(
        '/user/$targetUid',
        responseType: LuoguResponseType.lentille,
      );
    } on AppException catch (error) {
      if (_shouldUseSessionFallback(error)) {
        return _sessionFallbackProfile(targetUid);
      }
      rethrow;
    }

    final data = LuoguJson.unwrap(json);
    final user = LuoguJson.mapAt(data, 'user').isEmpty
        ? data
        : LuoguJson.mapAt(data, 'user');
    final gu = LuoguJson.mapAt(data, 'gu');
    final scores = LuoguJson.mapAt(gu, 'scores');

    return UserProfile(
      name: LuoguJson.stringValue(
        user,
        const ['name', 'username'],
        fallback: '洛谷用户',
      ),
      uid: LuoguJson.stringValue(
        user,
        const ['uid', 'id'],
        fallback: targetUid,
      ),
      rankName: LuoguJson.stringValue(
        user,
        const ['badge', 'color', 'rank'],
        fallback: '用户',
      ),
      acceptedCount: LuoguJson.intValue(
        user,
        const ['passedProblemCount', 'acceptedProblemCount', 'accepted'],
        fallback: LuoguJson.intValue(scores, const ['practice'], fallback: 0),
      ),
      submissionCount: LuoguJson.intValue(
        user,
        const ['submittedProblemCount', 'submitted'],
        fallback: 0,
      ),
      ranking: LuoguJson.intValue(user, const ['ranking', 'rank'], fallback: 0),
      valuation: LuoguJson.intValue(gu, const ['rating'], fallback: 0),
      avatarUrl: _avatarUrl(user, targetUid),
      backgroundUrl: LuoguJson.stringValue(
        user,
        const ['background', 'backgroundUrl'],
      ),
      slogan: LuoguJson.stringValue(user, const ['slogan']),
      introduction: LuoguJson.stringValue(
        user,
        const ['introduction', 'bio'],
      ),
    );
  }

  String _avatarUrl(Map<String, Object?> user, String uid) {
    final raw = LuoguJson.stringValue(user, const ['avatar']);
    if (raw.startsWith('http')) {
      return raw;
    }
    if (raw.startsWith('//')) {
      return 'https:$raw';
    }
    if (raw.startsWith('/')) {
      return 'https://cdn.luogu.com.cn$raw';
    }

    return 'https://cdn.luogu.com.cn/upload/usericon/$uid.png';
  }

  UserProfile _guestProfile() {
    return const UserProfile(
      name: 'Flowgu',
      uid: '-',
      rankName: '未登录',
      acceptedCount: 0,
      submissionCount: 0,
      ranking: 0,
      valuation: 0,
      slogan: '登录洛谷账号后会自动同步个人资料、提交记录和题单。',
      introduction: '当前是本地访客状态，不会请求洛谷用户接口。',
    );
  }

  UserProfile _sessionFallbackProfile(String uid) {
    return UserProfile(
      name: uid == '-' ? 'Flowgu' : 'Luogu #$uid',
      uid: uid,
      rankName: '已登录',
      acceptedCount: 0,
      submissionCount: 0,
      ranking: 0,
      valuation: 0,
      avatarUrl: uid == '-'
          ? null
          : 'https://cdn.luogu.com.cn/upload/usericon/$uid.png',
      slogan: '洛谷会话已保存，但用户资料接口暂时不可用。',
      introduction: '提交记录、题单等需要登录的功能仍会继续使用当前 Cookie。',
    );
  }

  bool _shouldUseSessionFallback(AppException error) {
    final message = error.message;
    return message.contains('HTTP 404') ||
        message.contains('用户信息加载失败') ||
        message.contains('洛谷接口请求失败');
  }
}
