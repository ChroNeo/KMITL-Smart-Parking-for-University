import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_parking_for_university/config.dart';
import 'package:smart_parking_for_university/models/api_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  Future<Map<String, dynamic>> login(
    String email,
    String password, {
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    final uri = Uri.parse('${AppConfig.baseApiUrl}/login');

    try {
      final res = await c
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        final msg =
            (data['error']?['message'] ?? data['message'] ?? 'Login failed')
                .toString();
        throw ApiException(msg, statusCode: res.statusCode);
      }

      final token = (data['access_token'] ?? data['token'])?.toString();
      if (token == null || token.isEmpty) {
        throw ApiException('Missing access token', statusCode: res.statusCode);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt', token);

      // ใส่ message เองถ้า backend ไม่ส่งมา
      data['message'] ??= 'เข้าสู่ระบบสำเร็จ';
      return data;
    } on TimeoutException {
      throw ApiException('Request timed out');
    } on SocketException {
      throw ApiException('Network error. Check connection.');
    } on FormatException {
      throw ApiException('Invalid JSON.');
    } finally {
      if (client == null) c.close();
    }
  }

  Future<Map<String, dynamic>> register(
    RegisterRequest req, {
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    final uri = Uri.parse('${AppConfig.baseApiUrl}/register');

    try {
      final res = await c
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(req.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      // JSON 100%
      final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        final msg =
            (data['error']?['message'] ?? data['message'] ?? 'Request failed')
                .toString();
        throw ApiException(msg, statusCode: res.statusCode);
      }

      return data;
    } on TimeoutException {
      throw ApiException('Request timed out');
    } on SocketException {
      throw ApiException('Network error. Check connection.');
    } on FormatException {
      throw ApiException('Invalid JSON.');
    } finally {
      if (client == null) c.close();
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt');
  } // Helper function to safely parse JSON

  Map<String, dynamic> _safeJson(String s) {
    try {
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      return {'raw': s};
    }
  }

  Future<String?> getMe() async {
    final token = await getToken();
    final uri = Uri.parse('${AppConfig.baseApiUrl}/me');
    final res = await http.get(
      uri,
      headers: {'authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      final data = _safeJson(res.body);
      final msg = data['error']?['message'] ?? 'Request failed';
      throw Exception(msg);
    }
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> updateMe({
    required String fullName,
    required String phoneNumber,
    required String carBrand,
    required String carRegistration,
    required String carProvince,
  }) async {
    final uri = Uri.parse('${AppConfig.baseApiUrl}/me');
    final res = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'authorization': 'Bearer ${await getToken()}',
      },
      body: jsonEncode({
        "full_name": fullName,
        "phone_number": phoneNumber,
        "car_brand": carBrand,
        "car_registration": carRegistration,
        "car_province": carProvince,
      }),
    );

    final data = jsonDecode(res.body);
    return {
      'success': res.statusCode == 200,
      'status': res.statusCode,
      'data': data,
    };
  }

  Future<bool> hasJWT() async {
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.baseApiUrl}/me'),
        headers: {'authorization': 'Bearer ${await getToken()}'},
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ตัวอย่างยิง API ที่ต้องใช้โทเคน
  Future<dynamic> getSlotsStatus() async {
    final token = await getToken();
    final uri = Uri.parse('${AppConfig.baseApiUrl}/slots/status');
    final res = await http.get(
      uri,
      headers: {'authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      final data = _safeJson(res.body);
      final msg = data['error']?['message'] ?? 'Request failed';
      throw Exception(msg);
    }
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> reserveSlot(int slotNumber) async {
    final uri = Uri.parse('${AppConfig.baseApiUrl}/reservation');
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'authorization': 'Bearer ${await getToken()}',
      },
      body: jsonEncode({'slot_number': slotNumber}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) {
      return {'success': false, 'status': res.statusCode, 'data': data};
    }
    return data;
  }
}
