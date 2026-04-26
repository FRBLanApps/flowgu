import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_environment.dart';
import '../errors/app_exception.dart';
import 'app_session.dart';

enum LuoguResponseType {
  normal,
  data,
  lentille,
}

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    this.baseUrl = AppEnvironment.apiBaseUrl,
    this.timeout = const Duration(seconds: 12),
  }) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  final String baseUrl;
  final Duration timeout;

  Future<Map<String, Object?>> getJson(
    String path, {
    Map<String, String?> query = const {},
    LuoguResponseType responseType = LuoguResponseType.normal,
  }) async {
    final uri = _buildUri(path, query, responseType);

    try {
      final response = await _httpClient
          .get(uri, headers: _headers(responseType))
          .timeout(timeout);
      _absorbSession(response);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppException(
          '洛谷接口请求失败: HTTP ${response.statusCode} ${_preview(response.body)}',
        );
      }

      return _decodeJsonObject(response.body);
    } on TimeoutException {
      throw const AppException('洛谷接口请求超时');
    } on http.ClientException catch (error) {
      if (kIsWeb) {
        throw AppException('浏览器阻止了跨域请求，已切换到本地题库数据: ${error.message}');
      }

      throw AppException('网络请求失败: ${error.message}');
    } on FormatException catch (error) {
      throw AppException('洛谷接口解析失败: ${error.message}');
    }
  }

  Future<String> getText(
    String path, {
    Map<String, String?> query = const {},
  }) async {
    final uri = _buildUri(path, query, LuoguResponseType.normal);

    try {
      final response =
          await _httpClient.get(uri, headers: _textHeaders()).timeout(timeout);
      _absorbSession(response);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppException(
          '网页请求失败: HTTP ${response.statusCode} ${_preview(response.body)}',
        );
      }

      return response.body;
    } on TimeoutException {
      throw const AppException('网页请求超时');
    } on http.ClientException catch (error) {
      throw AppException('网页请求失败: ${error.message}');
    }
  }

  Future<Uint8List> getBytes(
    String path, {
    Map<String, String?> query = const {},
  }) async {
    final uri = _buildUri(path, query, LuoguResponseType.normal);

    try {
      final response =
          await _httpClient.get(uri, headers: _textHeaders()).timeout(timeout);
      _absorbSession(response);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppException(
          '资源请求失败: HTTP ${response.statusCode} ${_preview(response.body)}',
        );
      }

      return response.bodyBytes;
    } on TimeoutException {
      throw const AppException('资源请求超时');
    } on http.ClientException catch (error) {
      throw AppException('资源请求失败: ${error.message}');
    }
  }

  Future<String?> fetchCsrfToken(String path) async {
    final html = await getText(path);
    final match = RegExp(
      "<meta\\s+name=['\"]csrf-token['\"]\\s+content=['\"]([^'\"]+)['\"]",
      caseSensitive: false,
    ).firstMatch(html);

    return match?.group(1);
  }

  Future<Map<String, Object?>> postJson(
    String path, {
    Map<String, String?> query = const {},
    required Map<String, Object?> body,
    String? csrfToken,
  }) async {
    final uri = _buildUri(path, query, LuoguResponseType.normal);

    try {
      final response = await _httpClient
          .post(
            uri,
            headers: _postHeaders(csrfToken),
            body: jsonEncode(body),
          )
          .timeout(timeout);
      _absorbSession(response);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppException(
          '洛谷接口请求失败: HTTP ${response.statusCode} ${_preview(response.body)}',
        );
      }

      return _decodeJsonObject(response.body);
    } on TimeoutException {
      throw const AppException('洛谷接口请求超时');
    } on http.ClientException catch (error) {
      if (kIsWeb) {
        throw AppException('浏览器阻止了跨域提交请求: ${error.message}');
      }

      throw AppException('网络请求失败: ${error.message}');
    } on FormatException catch (error) {
      throw AppException('洛谷接口解析失败: ${error.message}');
    }
  }

  Future<Map<String, Object?>> postForm(
    String path, {
    Map<String, String?> query = const {},
    required Map<String, String> body,
    String? csrfToken,
  }) async {
    final uri = _buildUri(path, query, LuoguResponseType.normal);

    try {
      final response = await _httpClient
          .post(
            uri,
            headers: _formHeaders(csrfToken),
            body: body,
          )
          .timeout(timeout);
      _absorbSession(response);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppException(
          '洛谷接口请求失败: HTTP ${response.statusCode} ${_preview(response.body)}',
        );
      }

      if (response.body.trim().isEmpty) {
        return const {};
      }

      return _decodeJsonObject(response.body);
    } on TimeoutException {
      throw const AppException('洛谷接口请求超时');
    } on http.ClientException catch (error) {
      if (kIsWeb) {
        throw AppException('浏览器阻止了跨域登录请求: ${error.message}');
      }

      throw AppException('网络请求失败: ${error.message}');
    } on FormatException catch (error) {
      throw AppException('洛谷接口解析失败: ${error.message}');
    }
  }

  Future<String> postFormText(
    String path, {
    Map<String, String?> query = const {},
    required Map<String, String> body,
    String? csrfToken,
  }) async {
    final uri = _buildUri(path, query, LuoguResponseType.normal);

    try {
      final response = await _httpClient
          .post(
            uri,
            headers: _formHeaders(csrfToken),
            body: body,
          )
          .timeout(timeout);
      _absorbSession(response);

      if (response.statusCode < 200 || response.statusCode >= 400) {
        throw AppException(
          '表单提交失败: HTTP ${response.statusCode} ${_preview(response.body)}',
        );
      }

      return response.body;
    } on TimeoutException {
      throw const AppException('表单提交超时');
    } on http.ClientException catch (error) {
      throw AppException('表单提交失败: ${error.message}');
    }
  }

  Uri _buildUri(
    String path,
    Map<String, String?> query,
    LuoguResponseType responseType,
  ) {
    final base = Uri.parse(baseUrl);
    final filteredQuery = <String, String>{};

    for (final entry in query.entries) {
      final value = entry.value;
      if (value != null && value.isNotEmpty) {
        filteredQuery[entry.key] = value;
      }
    }

    if (responseType == LuoguResponseType.data) {
      filteredQuery['_contentOnly'] = '1';
    }

    return base.replace(
      path: path,
      queryParameters: filteredQuery.isEmpty ? null : filteredQuery,
    );
  }

  Map<String, String> _headers(LuoguResponseType responseType) {
    return {
      'accept': 'application/json, text/plain, */*',
      if (!kIsWeb) 'user-agent': AppEnvironment.defaultUserAgent,
      if (!kIsWeb && AppSession.cookieHeader != null)
        'cookie': AppSession.cookieHeader!,
      if (responseType == LuoguResponseType.data)
        'x-luogu-type': 'content-only',
      if (responseType == LuoguResponseType.lentille)
        'x-lentille-request': 'content-only',
    };
  }

  Map<String, String> _textHeaders() {
    return {
      'accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      if (!kIsWeb) 'user-agent': AppEnvironment.defaultUserAgent,
      if (!kIsWeb && AppSession.cookieHeader != null)
        'cookie': AppSession.cookieHeader!,
    };
  }

  Map<String, String> _postHeaders(String? csrfToken) {
    return {
      'accept': 'application/json, text/plain, */*',
      'content-type': 'application/json;charset=UTF-8',
      'referer': '$baseUrl/',
      if (!kIsWeb) 'user-agent': AppEnvironment.defaultUserAgent,
      if (!kIsWeb && AppSession.cookieHeader != null)
        'cookie': AppSession.cookieHeader!,
      if (csrfToken != null && csrfToken.isNotEmpty) 'x-csrf-token': csrfToken,
    };
  }

  Map<String, String> _formHeaders(String? csrfToken) {
    return {
      'accept': 'application/json, text/plain, */*',
      'content-type': 'application/x-www-form-urlencoded;charset=UTF-8',
      'referer': '$baseUrl/',
      if (!kIsWeb) 'user-agent': AppEnvironment.defaultUserAgent,
      if (!kIsWeb && AppSession.cookieHeader != null)
        'cookie': AppSession.cookieHeader!,
      if (csrfToken != null && csrfToken.isNotEmpty) 'x-csrf-token': csrfToken,
    };
  }

  void _absorbSession(http.Response response) {
    AppSession.absorbSetCookieHeader(response.headers['set-cookie']);
  }

  Map<String, Object?> _decodeJsonObject(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return Map<String, Object?>.from(decoded);
      }
    } on FormatException {
      final embedded = _extractLentilleContext(body);
      if (embedded != null) {
        final decoded = jsonDecode(embedded);
        if (decoded is Map) {
          return Map<String, Object?>.from(decoded);
        }
      }

      if (body.contains('/auth/login')) {
        throw const AppException('该洛谷接口需要登录后才能访问');
      }

      rethrow;
    }

    throw const AppException('洛谷接口返回格式不是 JSON 对象');
  }

  String? _extractLentilleContext(String body) {
    final match = RegExp(
      r'<script id="lentille-context" type="application/json">(.+?)</script>',
      dotAll: true,
    ).firstMatch(body);

    return match?.group(1);
  }

  String _preview(String body) {
    final normalized = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 120) {
      return normalized;
    }

    return '${normalized.substring(0, 120)}...';
  }
}
