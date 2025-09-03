import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:smart_parking_for_university/pages/dashboard.dart';
import 'package:smart_parking_for_university/pages/edit_page.dart';
import 'package:smart_parking_for_university/pages/home.dart';
import 'package:smart_parking_for_university/pages/login_page.dart';
import 'package:smart_parking_for_university/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

final _api = ApiService();

Future<bool> _isAdmin() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null || token.isEmpty) return false;

    final claims = JwtDecoder.decode(token);

    // Common patterns for admin flag/role
    final role = (claims['role'] ?? claims['user_role'])?.toString().toLowerCase();
    if (role == 'admin') return true;

    final roles = claims['roles'];
    if (roles is List) {
      if (roles.map((e) => e.toString().toLowerCase()).contains('admin')) {
        return true;
      }
    }

    final rawAdmin = claims['is_admin'] ?? claims['isAdmin'] ?? claims['admin'];
    if (rawAdmin is bool) return rawAdmin;
    if (rawAdmin is num) return rawAdmin == 1;
    if (rawAdmin is String) {
      final v = rawAdmin.toLowerCase();
      return v == 'true' || v == '1' || v == 'yes';
    }
  } catch (_) {
    // ignore decoding errors -> treat as non-admin
  }
  return false;
}
Widget hamburger(context) {
  return Drawer(
    backgroundColor: const Color(0xFFE0FBDB),
    child: FutureBuilder<bool>(
      future: _isAdmin(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data == true; // default false while loading
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
          children: [
            if (isAdmin) ...[
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Dashboard()),
                  );
                },
                child: const Text('หน้า Dashboard'),
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Home()),
                );
              },
              child: const Text('หน้าการจองรถ'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditCarPage()),
                );
              },
              child: const Text('หน้าแก้ไขข้อมูล'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await _api.logout();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text('ออกจากระบบ'),
            ),
          ],
        );
      },
    ),
  );
}
