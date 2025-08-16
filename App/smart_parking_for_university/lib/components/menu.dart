import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:smart_parking_for_university/pages/dashboard.dart';

Widget hamburger(context){
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
            ElevatedButton(onPressed: () {}, child: const Text('หน้าการจองรถ')),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {},
              child: const Text('หน้าแก้ไขข้อมูล'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () {}, child: const Text('ออกจากระบบ')),
          ],
        ),
      );
}
