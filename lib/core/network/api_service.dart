import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  /*
   * ============================================================
   * HASANI ARMS API SERVICE
   * ============================================================
   *
   * Production backend:
   *
   * https://hasaniarms.onrender.com
   *
   * The API URL can also be supplied during the Flutter build:
   *
   * --dart-define=API_BASE_URL=https://hasaniarms.onrender.com
   *
   * The session cookie returned by the backend is stored locally
   * and sent with subsequent API requests.
   */

  static const String _cookieKey = 'hasani_session_cookie';

  final String baseUrl;

  ApiService({String? baseUrl})
      : baseUrl = _normalizeBaseUrl(
          baseUrl ??
              const String.fromEnvironment(
                'API_BASE_URL',
                defaultValue: 'https://hasaniarms.onrender.com',
              ),
        );

  // ============================================================
  // NORMALIZE URL
  // ============================================================

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

    final cookie = prefs.getString(_cookieKey);

    if (cookie == null || cookie.trim().isEmpty) {
      return null;
    }

    return cookie.trim();
  }

  // ============================================================
  // SAVE SESSION COOKIE
  // ============================================================

  Future<void> _saveCookie(http.Response response) async {
    /*
     * Express sends:
     *
     * Set-Cookie:
     * hasani_customer_sid=....; Path=/; HttpOnly; Secure; ...
     *
     * We only need:
     *
     * hasani_customer_sid=....
     */

    final setCookie = response.headers['set-cookie'];

    if (setCookie == null || setCookie.trim().isEmpty) {
      return;
    }

    String? cookie;

    /*
     * Normally Dart's http package exposes Set-Cookie as a header.
     *
     * Find the actual cookie portion before the first semicolon.
     */
    final parts = setCookie.split(';');

    if (parts.isNotEmpty) {
      final firstPart = parts.first.trim();

      if (firstPart.contains('=')) {
        cookie = firstPart;
      }
    }

    if (cookie == null || cookie.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _cookieKey,
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

    try {
      final headers = await _headers();

      final response = await http.get(
        uri,
        headers: headers,
      );

      /*
       * Some endpoints can refresh/set the session cookie.
       */
      await _saveCookie(response);

      return _decode(
        response,
        path: path,
      );
    } on Exception catch (e) {
      /*
       * Preserve server/API errors.
       *
       * Only convert actual connection errors into the
       * connection message.
       */
      if (e.toString().contains('Hasani server returned HTTP')) {
        rethrow;
      }

      throw Exception(
        'Unable to connect to Hasani server.\n\n'
        'Server: $baseUrl\n\n'
        'Please check your internet connection and try again.',
      );
    }
  }

  // ============================================================
  // POST
  // ============================================================

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl$path');

    /*
     * If this is a new login, remove an old/stale session first.
     *
     * This prevents an expired cookie from interfering with
     * the new login.
     */
    final isLogin = _isCustomerLogin(path);

    if (isLogin) {
      await clearSession();
    }

    try {
      final headers = await _headers(
        json: true,
      );

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      /*
       * VERY IMPORTANT:
       *
       * Save the session cookie BEFORE decoding the response.
       *
       * The login endpoint creates the customer session here.
       */
      await _saveCookie(response);

      final data = _decode(
        response,
        path: path,
      );

      /*
       * If this was logout, remove the local cookie.
       */
      if (_isCustomerLogout(path)) {
        await clearSession();
      }

      return data;
    } on Exception catch (e) {
      /*
       * Preserve HTTP errors such as 401, 403, 404, etc.
       */
      if (e.toString().contains('Hasani server returned HTTP')) {
        rethrow;
      }

      throw Exception(
        'Unable to connect to Hasani server.\n\n'
        'Server: $baseUrl\n\n'
        'Please check your internet connection and try again.',
      );
    }
  }

  // ============================================================
  // LOGIN DETECTION
  // ============================================================

  bool _isCustomerLogin(String path) {
    final normalized = path.toLowerCase();

    return normalized.contains('/customer/login');
  }

  // ============================================================
  // LOGOUT DETECTION
  // ============================================================

  bool _isCustomerLogout(String path) {
    final normalized = path.toLowerCase();

    return normalized.contains('/customer/logout');
  }

  // ============================================================
  // RESPONSE DECODER
  // ============================================================

  Map<String, dynamic> _decode(
    http.Response response, {
    String? path,
  }) {
    Map<String, dynamic> data;

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        data = decoded;
      } else if (decoded is Map) {
        data = Map<String, dynamic>.from(decoded);
      } else {
        data = {
          'error': 'Invalid server response',
        };
      }
    } catch (_) {
      data = {
        'error': response.body.isNotEmpty
            ? response.body
            : 'Invalid server response',
      };
    }

    // ==========================================================
    // SUCCESS
    // ==========================================================

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    // ==========================================================
    // SESSION EXPIRED
    // ==========================================================

    if (response.statusCode == 401) {
      /*
       * If the server says the session is invalid, remove the
       * stale local cookie.
       *
       * The next login will start a completely fresh session.
       */
      clearSession();

      throw Exception(
        'Hasani server returned HTTP 401.\n\n'
        '${data['error'] ?? data['message'] ?? 'Customer session expired. Please log in again.'}',
      );
    }

    // ==========================================================
    // FORBIDDEN
    // ==========================================================

    if (response.statusCode == 403) {
      throw Exception(
        'Hasani server returned HTTP 403.\n\n'
        '${data['error'] ?? data['message'] ?? 'Access denied.'}',
      );
    }

    // ==========================================================
    // NOT FOUND
    // ==========================================================

    if (response.statusCode == 404) {
      throw Exception(
        'Hasani server returned HTTP 404.\n\n'
        '${data['error'] ?? data['message'] ?? 'API endpoint not found.'}',
      );
    }

    // ==========================================================
    // OTHER SERVER ERRORS
    // ==========================================================

    throw Exception(
      'Hasani server returned HTTP ${response.statusCode}.\n\n'
      '${data['error'] ?? data['message'] ?? 'Request failed.'}',
    );
  }

  // ============================================================
  // CLEAR SESSION
  // ============================================================

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_cookieKey);
  }

  // ============================================================
  // CHECK WHETHER A LOCAL SESSION EXISTS
  // ============================================================

  Future<bool> hasSession() async {
    final cookie = await _getCookie();

    return cookie != null && cookie.isNotEmpty;
  }

  // ============================================================
  // DEBUG INFORMATION
  // ============================================================

  Future<String> debugSession() async {
    final cookie = await _getCookie();

    if (cookie == null || cookie.isEmpty) {
      return 'No Hasani customer session cookie stored.';
    }

    /*
     * Do not expose the complete session ID.
     */
    final separatorIndex = cookie.indexOf('=');

    if (separatorIndex == -1) {
      return 'Session cookie exists.';
    }

    final name = cookie.substring(0, separatorIndex);

    return 'Hasani customer session cookie exists: $name=***';
  }
}
