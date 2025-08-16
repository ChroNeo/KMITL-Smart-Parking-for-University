import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = "http://10.0.2.2:3000/api/v1";

  Future<Map<String, dynamic>> login(String email, String password) async {
    final uri = Uri.parse('$baseUrl/login');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = _safeJson(res.body);
    if (res.statusCode != 200) {
      final msg = data['error']?['message'] ?? 'Login failed';
      throw Exception(msg);
    }

    final token = data['access_token'] as String;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt', token);               // เก็บไว้ใช้ต่อ
    return data;                                       // มี { token, user, ... }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt');
  }

  Map<String, dynamic> _safeJson(String s) {
    try { return jsonDecode(s) as Map<String, dynamic>; }
    catch (_) { return {'raw': s}; }
  }

  // ตัวอย่างยิง API ที่ต้องใช้โทเคน
  Future<dynamic> getSlotsStatus() async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/slots/status');
    final res = await http.get(uri, headers: {
      'authorization': 'Bearer $token',
    });
    if (res.statusCode != 200) {
      final data = _safeJson(res.body);
      final msg = data['error']?['message'] ?? 'Request failed';
      throw Exception(msg);
    }
    return jsonDecode(res.body);
  }
}
