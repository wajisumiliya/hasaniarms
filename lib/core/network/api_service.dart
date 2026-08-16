import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl;
  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:5000');

  Future<String?> _cookie() async => (await SharedPreferences.getInstance()).getString('hasani_session_cookie');

  Future<void> _saveCookie(http.Response response) async {
    final setCookie = response.headers['set-cookie'];
    if (setCookie == null) return;
    final first = setCookie.split(';').first.trim();
    if (first.isNotEmpty) (await SharedPreferences.getInstance()).setString('hasani_session_cookie', first);
  }

  Future<Map<String, dynamic>> get(String path) async {
    final headers = <String, String>{'Accept': 'application/json'};
    final cookie = await _cookie();
    if (cookie != null) headers['Cookie'] = cookie;
    final r = await http.get(Uri.parse('$baseUrl$path'), headers: headers);
    return _decode(r);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final headers = <String, String>{'Content-Type': 'application/json', 'Accept': 'application/json'};
    final cookie = await _cookie();
    if (cookie != null) headers['Cookie'] = cookie;
    final r = await http.post(Uri.parse('$baseUrl$path'), headers: headers, body: jsonEncode(body));
    await _saveCookie(r);
    final data = _decode(r);
    if (path.contains('/customer/logout')) await clearSession();
    return data;
  }

  Map<String, dynamic> _decode(http.Response r) {
    Map<String, dynamic> d;
    try { d = jsonDecode(r.body) as Map<String, dynamic>; } catch (_) { d = {'error': 'Invalid server response'}; }
    if (r.statusCode >= 400) throw Exception(d['error'] ?? 'Request failed');
    return d;
  }

  Future<void> clearSession() async => (await SharedPreferences.getInstance()).remove('hasani_session_cookie');
}
