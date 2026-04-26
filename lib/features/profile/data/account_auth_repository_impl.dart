import '../../../core/network/api_client.dart';
import '../../../core/network/app_session.dart';
import '../../../core/network/luogu_json.dart';
import '../domain/models/account_auth.dart';
import '../domain/models/linked_account.dart';
import '../domain/repositories/account_auth_repository.dart';

class AccountAuthRepositoryImpl implements AccountAuthRepository {
  AccountAuthRepositoryImpl({
    ApiClient? luoguClient,
    ApiClient? atCoderClient,
  })  : _luoguClient = luoguClient ?? ApiClient(),
        _atCoderClient =
            atCoderClient ?? ApiClient(baseUrl: 'https://atcoder.jp');

  final ApiClient _luoguClient;
  final ApiClient _atCoderClient;

  @override
  Future<AccountAuthResult> connect(AccountAuthRequest request) {
    return switch (request.platform) {
      AccountPlatform.luogu => _connectLuogu(request),
      AccountPlatform.atcoder => _connectAtCoder(request),
    };
  }

  @override
  Future<void> disconnect() async {
    AppSession.clear();
  }

  Future<AccountAuthResult> _connectLuogu(AccountAuthRequest request) async {
    if (request.mode == AccountLoginMode.cookie) {
      AppSession.setCookieHeader(request.cookie);
      if (!AppSession.hasLuoguSession) {
        throw const FormatException('Cookie 中需要包含 _uid 和 __client_id');
      }

      final profile = await _fetchLuoguProfile(AppSession.luoguUid!);
      return AccountAuthResult(
        account: LinkedAccount(
          platform: AccountPlatform.luogu,
          username: profile.username,
          isConnected: true,
          detail: 'UID ${profile.uid}',
        ),
        message: 'auth.luoguCookieVerified',
      );
    }

    final csrfToken = await _luoguClient.fetchCsrfToken('/');
    final json = await _luoguClient.postForm(
      '/do-auth/password',
      csrfToken: csrfToken,
      body: {
        'username': request.username,
        'password': request.password,
        if (request.captcha.trim().isNotEmpty)
          'captcha': request.captcha.trim(),
      },
    );
    final data = LuoguJson.unwrap(json);
    final user = LuoguJson.mapAt(data, 'user');
    final uid = LuoguJson.stringValue(
      user,
      const ['uid', 'id'],
      fallback: AppSession.luoguUid ?? '',
    );
    final username = LuoguJson.stringValue(
      user,
      const ['name', 'username'],
      fallback: request.username,
    );

    return AccountAuthResult(
      account: LinkedAccount(
        platform: AccountPlatform.luogu,
        username: username,
        isConnected: true,
        detail: uid.isEmpty ? '已登录' : 'UID $uid',
      ),
      message: 'auth.luoguLoginSuccess',
    );
  }

  Future<AccountAuthResult> _connectAtCoder(AccountAuthRequest request) async {
    final username = request.username.trim();
    if (username.isEmpty) {
      throw const FormatException('请输入 AtCoder 用户名');
    }

    if (request.mode == AccountLoginMode.password) {
      if (request.password.isEmpty) {
        throw const FormatException('请输入 AtCoder 密码');
      }

      final loginHtml = await _atCoderClient.getText('/login');
      final csrfToken = _firstMatch(
        loginHtml,
        r'''name=["']csrf_token["']\s+value=["']([^"']+)["']''',
      );
      if (csrfToken == null || csrfToken.isEmpty) {
        throw const FormatException('无法读取 AtCoder 登录令牌');
      }
      final resultHtml = await _atCoderClient.postFormText(
        '/login',
        body: {
          'username': username,
          'password': request.password,
          'csrf_token': csrfToken,
        },
      );
      if (resultHtml.contains('Username or Password is incorrect') ||
          resultHtml.contains('ユーザ名またはパスワードが違います')) {
        throw const FormatException('AtCoder 用户名或密码错误');
      }
    }

    final html = await _atCoderClient.getText('/users/$username');
    if (html.contains('The requested URL was not found') ||
        html.contains('404 Not Found')) {
      throw const FormatException('AtCoder 用户不存在');
    }

    final rating = _firstMatch(html, r'<th>Rating</th>\s*<td[^>]*>(.*?)</td>');
    final highest =
        _firstMatch(html, r'<th>Highest Rating</th>\s*<td[^>]*>(.*?)</td>');
    final detail = [
      if (rating != null && rating.isNotEmpty) 'Rating ${_stripHtml(rating)}',
      if (highest != null && highest.isNotEmpty) '最高 ${_stripHtml(highest)}',
    ].join(' · ');

    return AccountAuthResult(
      account: LinkedAccount(
        platform: AccountPlatform.atcoder,
        username: username,
        isConnected: true,
        detail: detail.isEmpty ? '公开资料已同步' : detail,
      ),
      message: request.mode == AccountLoginMode.password
          ? 'auth.atcoderLoginSuccess'
          : 'auth.atcoderProfileSynced',
    );
  }

  Future<_LuoguProfileRef> _fetchLuoguProfile(String uid) async {
    final json = await _luoguClient.getJson(
      '/user/$uid',
      responseType: LuoguResponseType.lentille,
    );
    final data = LuoguJson.unwrap(json);
    final user = LuoguJson.mapAt(data, 'user').isEmpty
        ? data
        : LuoguJson.mapAt(data, 'user');

    return _LuoguProfileRef(
      uid: LuoguJson.stringValue(user, const ['uid', 'id'], fallback: uid),
      username: LuoguJson.stringValue(
        user,
        const ['name', 'username'],
        fallback: '洛谷用户',
      ),
    );
  }

  String? _firstMatch(String html, String pattern) {
    return RegExp(pattern, caseSensitive: false, dotAll: true)
        .firstMatch(html)
        ?.group(1);
  }

  String _stripHtml(String value) {
    return value
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }
}

class _LuoguProfileRef {
  const _LuoguProfileRef({
    required this.uid,
    required this.username,
  });

  final String uid;
  final String username;
}
