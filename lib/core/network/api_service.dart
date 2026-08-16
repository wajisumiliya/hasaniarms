import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  /*
   * ============================================================
   * HASANI ARMS API SERVICE
   * ============================================================
   *
   * Production APK:
   *
   * https://hasaniarms.onrender.com
   *
   * GitHub Actions supplies:
   *
   * --dart-define=API_BASE_URL=https://hasaniarms.onrender.com
   *
   * IMPORTANT:
   * localhost / 192.168.x.x must NOT be used in the production APK.
   */

  final String baseUrl;

  ApiService({String? baseUrl})
      : baseUrl = _normalizeBaseUrl(
          baseUrl ??
              const String.fromEnvironment(
                'API_BASE_URL',
                defaultValue: 'https://hasaniarms.onrender.com',
              ),
        );

  static String _normalizeBaseUrl(String value) {
    var url = value.trim();

    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }

    return url;
  }

  // ============================================================
  // SESSION COOKIE
  // ============================================================

  Future<String?> _getCookie() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('hasani_session_cookie');
  }

  Future<void> _saveCookie(http.Response response) async {
    final setCookie = response.headers['set-cookie'];

    if (setCookie == null || setCookie.isEmpty) {
      return;
    }

    /*
     * Example:
     *
     * connect.sid=xxxxx; Path=/; HttpOnly; Secure
     *
     * We only store:
     *
     * connect.sid=xxxxx
     */

    final cookie = setCookie.split(';').first.trim();

    if (cookie.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'hasani_session_cookie',
      cookie,
    );
  }

  // ============================================================
  // COMMON HEADERS
  // ============================================================

  Future<Map<String, String>> _headers({
    bool json = false,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (json) {
      headers['Content-Type'] = 'application/json';
    }

    final cookie = await _getCookie();

    if (cookie != null && cookie.isNotEmpty) {
      headers['Cookie'] = cookie;
    }

    return headers;
  }

  // ============================================================
  // GET
  // ============================================================

  Future<Map<String, dynamic>> get(String path) async {
    final uri = Uri.parse('$baseUrl$path');

    final headers = await _headers();

    http.Response response;

    try {
      response = await http
          .get(
            uri,
            headers: headers,
          )
          .timeout(
            const Duration(seconds: 30),
          );
    } on Exception catch (e) {
      throw Exception(
        'Unable to connect to Hasani server.\n\n'
        'Server: $baseUrl\n\n'
        'Network error: $e',
      );
    }

    /*
     * IMPORTANT:
     *
     * _decode() is intentionally OUTSIDE the try/catch above.
     *
     * This allows us to see real HTTP errors such as:
     *
     * 401
     * 403
     * 404
     * 500
     * 502
     */

    return _decode(response);
  }

  // ============================================================
  // POST
  // ============================================================

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl$path');

    final headers = await _headers(
      json: true,
    );

    http.Response response;

    try {
      response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 30),
          );
    } on Exception catch (e) {
      /*
       * ONLY genuine network/request failures come here.
       *
       * HTTP errors do NOT come here.
       */

      throw Exception(
        'Unable to connect to Hasani server.\n\n'
        'Server: $baseUrl\n\n'
        'Network error: $e',
      );
    }

    // Save session cookie if the backend supplied one.
    await _saveCookie(response);

    /*
     * Logout should clear the local session after the request.
     */

    final data = _decode(response);

    if (path.contains('/customer/logout')) {
      await clearSession();
    }

    return data;
  }

  // ============================================================
  // RESPONSE DECODER
  // ============================================================

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> data;

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        data = decoded;
      } else {
        data = {
          'error': 'Invalid server response',
          'statusCode': response.statusCode,
        };
      }
    } catch (_) {
      data = {
        'error': response.body.isNotEmpty
            ? response.body
            : 'Invalid server response',
        'statusCode': response.statusCode,
      };
    }

    // ==========================================================
    // SUCCESS
    // ==========================================================

    if (response.statusCode >= 200 &&
        response.statusCode < 400) {
      return data;
    }

    // ==========================================================
    // REAL SERVER ERROR
    // ==========================================================

    final errorMessage =
        data['error'] ??
        data['message'] ??
        data['detail'] ??
        'Request failed';

    throw Exception(
      'Hasani server returned HTTP ${response.statusCode}.\n\n'
      '$errorMessage',
    );
  }

  // ============================================================
  // CLEAR SESSION
  // ============================================================

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(
      'hasani_session_cookie',
    );
  }
}
