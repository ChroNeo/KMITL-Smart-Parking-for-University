import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:smart_parking_for_university/pages/dashboard.dart';
import 'package:smart_parking_for_university/pages/edit_page.dart';
import 'package:smart_parking_for_university/pages/home.dart';
import 'package:smart_parking_for_university/pages/login_page.dart';
import 'package:smart_parking_for_university/services/api_service.dart';

final _api = ApiService();
Widget hamburger(context) {
  return Drawer(
    backgroundColor: const Color(0xFFE0FBDB),
    child: ListView(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      children: [
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
    ),
  );
}
