import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  /*
  |--------------------------------------------------------------------------
  | HASANI ARMS API SERVICE
  |--------------------------------------------------------------------------
  |
  | Production backend:
  |
  | https://hasaniarms.onrender.com
  |
  | Build override:
  |
  | flutter build apk --release \
  |   --dart-define=API_BASE_URL=https://hasaniarms.onrender.com
  |
  */

  static const String _cookieKey =
      'hasani_session_cookie';

  final String baseUrl;

  ApiService({
    String? baseUrl,
  }) : baseUrl = _normalizeBaseUrl(
          baseUrl ??
              const String.fromEnvironment(
                'API_BASE_URL',
                defaultValue:
                    'https://hasaniarms.onrender.com',
              ),
        );

  // ==========================================================================
  // NORMALIZE BASE URL
  // ==========================================================================

  static String _normalizeBaseUrl(
    String value,
  ) {
    var url = value.trim();

    while (url.endsWith('/')) {
      url = url.substring(
        0,
        url.length - 1,
      );
    }

    return url;
  }

  // ==========================================================================
  // GET STORED COOKIE
  // ==========================================================================

  Future<String?> _getCookie() async {
    final prefs =
        await SharedPreferences.getInstance();

    final cookie =
        prefs.getString(_cookieKey);

    if (cookie == null ||
        cookie.trim().isEmpty) {
      return null;
    }

    return cookie.trim();
  }

  // ==========================================================================
  // SAVE SESSION COOKIE
  // ==========================================================================

  Future<void> _saveCookie(
    http.Response response,
  ) async {
    /*
     * Express normally returns:
     *
     * Set-Cookie:
     * hasani_customer_sid=ABC123;
     * Path=/;
     * HttpOnly;
     * Secure;
     *
     * We store only:
     *
     * hasani_customer_sid=ABC123
     */

    final rawSetCookie =
        response.headers['set-cookie'];

    if (rawSetCookie == null ||
        rawSetCookie.trim().isEmpty) {
      print(
        '[HASANI API] No Set-Cookie received.',
      );

      return;
    }

    var firstCookie =
        rawSetCookie.trim();

    /*
     * If the HTTP client combines multiple cookies,
     * take the first cookie.
     *
     * Our session cookie does not contain commas,
     * so this is safe for this backend.
     */
    if (firstCookie.contains(',')) {
      firstCookie =
          firstCookie.split(',').first.trim();
    }

    /*
     * Remove cookie attributes.
     *
     * Example:
     *
     * hasani_customer_sid=abc;
     * Path=/;
     * HttpOnly;
     *
     * becomes:
     *
     * hasani_customer_sid=abc
     */
    final cookie =
        firstCookie
            .split(';')
            .first
            .trim();

    if (!cookie.contains('=')) {
      print(
        '[HASANI API] Invalid Set-Cookie received.',
      );

      return;
    }

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _cookieKey,
      cookie,
    );

    print(
      '[HASANI API] Session cookie saved.',
    );
  }

  // ==========================================================================
  // CLEAR SESSION
  // ==========================================================================

  Future<void> clearSession() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      _cookieKey,
    );

    print(
      '[HASANI API] Local session cleared.',
    );
  }

  // ==========================================================================
  // COMMON HEADERS
  // ==========================================================================

  Future<Map<String, String>> _headers({
    bool json = false,
  }) async {
    final headers =
        <String, String>{
      'Accept':
          'application/json',
    };

    if (json) {
      headers['Content-Type'] =
          'application/json';
    }

    /*
     * Retrieve our manually stored Express
     * session cookie.
     */
    final cookie =
        await _getCookie();

    if (cookie != null &&
        cookie.isNotEmpty) {
      headers['Cookie'] =
          cookie;

      print(
        '[HASANI API] Sending stored session cookie.',
      );
    } else {
      print(
        '[HASANI API] No stored session cookie.',
      );
    }

    return headers;
  }

  // ==========================================================================
  // GET
  // ==========================================================================

  Future<Map<String, dynamic>> get(
    String path,
  ) async {
    final uri =
        Uri.parse(
      '$baseUrl$path',
    );

    try {
      final headers =
          await _headers();

      print(
        '[HASANI API] GET $uri',
      );

      final response =
          await http.get(
        uri,
        headers: headers,
      );

      print(
        '[HASANI API] GET ${response.statusCode} $path',
      );

      /*
       * Some endpoints can refresh the session cookie.
       */
      await _saveCookie(
        response,
      );

      return _decode(
        response,
        path: path,
      );
    } on Exception catch (e) {
      /*
       * Preserve HTTP/API errors.
       */
      if (e
          .toString()
          .contains(
            'Hasani server returned HTTP',
          )) {
        rethrow;
      }

      throw Exception(
        'Unable to connect to Hasani server.\n\n'
        'Server: $baseUrl\n\n'
        'Please check your internet connection and try again.',
      );
    }
  }

  // ==========================================================================
  // POST
  // ==========================================================================

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri =
        Uri.parse(
      '$baseUrl$path',
    );

    final isLogin =
        _isCustomerLogin(
      path,
    );

    /*
     * Remove any stale cookie before a fresh login.
     */
    if (isLogin) {
      print(
        '[HASANI API] New login - clearing old session.',
      );

      await clearSession();
    }

    try {
      final headers =
          await _headers(
        json: true,
      );

      print(
        '[HASANI API] POST $uri',
      );

      final response =
          await http.post(
        uri,
        headers: headers,
        body: jsonEncode(
          body,
        ),
      );

      print(
        '[HASANI API] POST ${response.statusCode} $path',
      );

      /*
       * VERY IMPORTANT:
       *
       * Save Set-Cookie before decoding.
       */
      await _saveCookie(
        response,
      );

      final data =
          _decode(
        response,
        path: path,
      );

      /*
       * Logout removes the local cookie.
       */
      if (_isCustomerLogout(path)) {
        await clearSession();
      }

      return data;
    } on Exception catch (e) {
      /*
       * Preserve HTTP errors.
       */
      if (e
          .toString()
          .contains(
            'Hasani server returned HTTP',
          )) {
        rethrow;
      }

      throw Exception(
        'Unable to connect to Hasani server.\n\n'
        'Server: $baseUrl\n\n'
        'Please check your internet connection and try again.',
      );
    }
  }

  // ==========================================================================
  // LOGIN DETECTION
  // ==========================================================================

  bool _isCustomerLogin(
    String path,
  ) {
    final normalized =
        path.toLowerCase();

    return normalized.contains(
      '/customer/login',
    );
  }

  // ==========================================================================
  // LOGOUT DETECTION
  // ==========================================================================

  bool _isCustomerLogout(
    String path,
  ) {
    final normalized =
        path.toLowerCase();

    return normalized.contains(
      '/customer/logout',
    );
  }

  // ==========================================================================
  // RESPONSE DECODER
  // ==========================================================================

  Map<String, dynamic> _decode(
    http.Response response, {
    String? path,
  }) {
    Map<String, dynamic> data;

    try {
      final decoded =
          jsonDecode(
        response.body,
      );

      if (decoded
          is Map<String, dynamic>) {
        data = decoded;
      } else if (decoded is Map) {
        data =
            Map<String, dynamic>.from(
          decoded,
        );
      } else {
        data = {
          'error':
              'Invalid server response',
        };
      }
    } catch (_) {
      data = {
        'error':
            response.body.isNotEmpty
                ? response.body
                : 'Invalid server response',
      };
    }

    // ------------------------------------------------------------------------
    // SUCCESS
    // ------------------------------------------------------------------------

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    // ------------------------------------------------------------------------
    // 401 SESSION EXPIRED
    // ------------------------------------------------------------------------

    if (response.statusCode == 401) {
      /*
       * Remove stale local cookie.
       *
       * We intentionally do not await here because this
       * method is synchronous.
       */
      clearSession();

      throw Exception(
        'Hasani server returned HTTP 401.\n\n'
        '${data['error'] ?? data['message'] ?? 'Customer session expired. Please log in again.'}',
      );
    }

    // ------------------------------------------------------------------------
    // 403 FORBIDDEN
    // ------------------------------------------------------------------------

    if (response.statusCode == 403) {
      throw Exception(
        'Hasani server returned HTTP 403.\n\n'
        '${data['error'] ?? data['message'] ?? 'Access denied.'}',
      );
    }

    // ------------------------------------------------------------------------
    // 404 NOT FOUND
    // ------------------------------------------------------------------------

    if (response.statusCode == 404) {
      throw Exception(
        'Hasani server returned HTTP 404.\n\n'
        '${data['error'] ?? data['message'] ?? 'API endpoint not found.'}',
      );
    }

    // ------------------------------------------------------------------------
    // OTHER HTTP ERRORS
    // ------------------------------------------------------------------------

    throw Exception(
      'Hasani server returned HTTP ${response.statusCode}.\n\n'
      '${data['error'] ?? data['message'] ?? 'Request failed.'}',
    );
  }

  // ==========================================================================
  // HAS SESSION
  // ==========================================================================

  Future<bool> hasSession() async {
    final cookie =
        await _getCookie();

    return cookie != null &&
        cookie.isNotEmpty;
  }

  // ==========================================================================
  // DEBUG SESSION
  // ==========================================================================

  Future<String> debugSession() async {
    final cookie =
        await _getCookie();

    if (cookie == null ||
        cookie.isEmpty) {
      return
          'No Hasani customer session cookie stored.';
    }

    final separatorIndex =
        cookie.indexOf('=');

    if (separatorIndex == -1) {
      return
          'Session cookie exists.';
    }

    final name =
        cookie.substring(
      0,
      separatorIndex,
    );

    return
        'Hasani customer session cookie exists: $name=***';
  }

  // ==========================================================================
  // DEBUG SESSION STATUS
  // ==========================================================================

  Future<Map<String, dynamic>>
      checkSessionStatus() async {
    try {
      return await get(
        '/api/customer/session-status',
      );
    } catch (e) {
      return {
        'ok': false,
        'error': e.toString(),
      };
    }
  }
}
