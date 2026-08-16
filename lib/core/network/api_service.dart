import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  /*
   * IMPORTANT
   *
   * The APK runs on your Android phone.
   * "localhost" means the PHONE itself.
   *
   * Set API_BASE_URL when building the APK:
   *
   * flutter build apk --debug \
   *   --dart-define=API_BASE_URL=http://YOUR_SERVER_IP:5000
   *
   * Example:
   *
   * --dart-define=API_BASE_URL=http://192.168.1.100:5000
   */

  final String baseUrl;

  ApiService({String? baseUrl})
      : baseUrl = _normalizeBaseUrl(
          baseUrl ??
              const String.fromEnvironment(
                'API_BASE_URL',
                defaultValue: 'http://192.168.1.100:5000',
              ),
        );

  static String _normalizeBaseUrl(String value) {
    var url = value.trim();

    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }

    return url;
  }

  Future<String?> _getCookie() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('hasani_session_cookie');
  }

  Future<void> _saveCookie(http.Response response) async {
    final setCookie = response.headers['set-cookie'];

    if (setCookie == null || setCookie.isEmpty) {
      return;
    }

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

  Future<Map<String, dynamic>> get(String path) async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    final cookie = await _getCookie();

    if (cookie != null && cookie.isNotEmpty) {
      headers['Cookie'] = cookie;
    }

    final uri = Uri.parse('$baseUrl$path');

    try {
      final response = await http.get(
        uri,
        headers: headers,
      );

      return _decode(response);
    } catch (e) {
      throw Exception(
        'Unable to connect to Hasani server.\n\n'
        'Server: $baseUrl\n\n'
        'Please check that the backend is running '
        'and the phone can reach the server.',
      );
    }
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final cookie = await _getCookie();

    if (cookie != null && cookie.isNotEmpty) {
      headers['Cookie'] = cookie;
    }

    final uri = Uri.parse('$baseUrl$path');

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      await _saveCookie(response);

      final data = _decode(response);

      if (path.contains('/customer/logout')) {
        await clearSession();
      }

      return data;
    } catch (e) {
      throw Exception(
        'Unable to connect to Hasani server.\n\n'
        'Server: $baseUrl\n\n'
        'Please check that the backend is running '
        'and the phone can reach the server.',
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> data;

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        data = decoded;
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

    if (response.statusCode >= 400) {
      throw Exception(
        data['error'] ??
            data['message'] ??
            'Request failed (${response.statusCode})',
      );
    }

    return data;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('hasani_session_cookie');
  }
}
