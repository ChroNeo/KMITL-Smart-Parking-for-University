import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:smart_parking_for_university/models/api_model.dart';
import 'package:smart_parking_for_university/services/api_service.dart';

class RegistorPage extends StatefulWidget {
  const RegistorPage({super.key});

  @override
  State<RegistorPage> createState() => _RegistorPageState();
}

class _RegistorPageState extends State<RegistorPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final fullnameController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final carBrandController = TextEditingController();
  final carRegistrationController = TextEditingController();
  final carProvinceController = TextEditingController();
  final _api = ApiService();
  Future<void> _submitForm() async {
    final user = RegisterRequest(
      email: emailController.text,
      password: passwordController.text,
      fullname: fullnameController.text,
      phoneNumber: phoneNumberController.text,
      carBrand: carBrandController.text,
      carRegistration: carRegistrationController.text,
      carProvince: carProvinceController.text,
    );
    try {
      await _doRegis(user); // async gap
      if (!mounted) return;
      showSuccessPopup(context);
    } catch (e) {
      if (!mounted) return;
      showErrorPopup(context, e.toString());
    }
  }

  Future<Map<String, dynamic>> _doRegis(RegisterRequest user) async {
    final res = await _api.register(user); // คืน JSON 100%
    return res;
  }

  void showSuccessPopup(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      pageBuilder: (context, _, __) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFDDF0D6), // พื้นหลังเขียวอ่อน
                border: Border.all(color: Colors.green, width: 1), // กรอบเขียว
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Text(
                          'ลงทะเบียนสำเร็จ',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(Icons.close, color: Colors.grey[700]),
                          onPressed: () => Navigator.pushNamed(context, '/login'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showErrorPopup(BuildContext context, [String message = '']) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      pageBuilder: (context, _, __) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE2E2), // พื้นหลังแดงอ่อน
                border: Border.all(color: Colors.red, width: 1), // กรอบแดง
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center, // ข้อความอยู่กลาง
                    children: [
                      Center(
                        child: Text(
                          'ดำเนินการไม่สำเร็จ',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(Icons.close, color: Colors.grey[700]),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: const Color(0xFFE0FBDB),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
          children: [
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
      ),

      backgroundColor: const Color(0xFFE0FBDB),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Column(
                    children: const [
                      Icon(Icons.directions_car, size: 48, color: Colors.black),
                      SizedBox(height: 8),
                      Text(
                        'ลงทะเบียน',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ข้อมูลทะเบียนรถ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInput(
                          'หมายเลขทะเบียนรถ',
                          carRegistrationController,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildInput(
                          'จังหวัดป้ายทะเบียน',
                          carProvinceController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ข้อมูลประเภทรถ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInput('ยี่ห้อรถยนต์', carBrandController),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ข้อมูลเจ้าของรถ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInput('ชื่อผู้ขับขี่/เจ้าของรถ', fullnameController),
                  const SizedBox(height: 12),
                  _buildInput('เบอร์ติดต่อ', phoneNumberController),
                  const SizedBox(height: 12),
                  _buildInput('Email', emailController),
                  const SizedBox(height: 12),
                  _buildInput('Password', passwordController, obscure: true),
                  const SizedBox(height: 24),

                  // Submit
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'บันทึก',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
    String hint,
    TextEditingController controller, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Colors.green),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Colors.green),
        ),
      ),
    );
  }
}
