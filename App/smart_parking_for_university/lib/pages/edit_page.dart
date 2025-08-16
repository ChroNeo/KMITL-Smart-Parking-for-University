import 'package:flutter/material.dart';

class EditCarPage extends StatefulWidget {
  const EditCarPage({super.key});

  @override
  State<EditCarPage> createState() => _EditCarPageState();
}

class _EditCarPageState extends State<EditCarPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final plateCtrl = TextEditingController();
  final provinceCtrl = TextEditingController();
  final brandCtrl = TextEditingController();
  final ownerCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  // Colors
  final bg = const Color(0xFFEFFBEF); // เขียวอ่อนพื้นหลัง
  final primaryGreen = const Color(0xFF3BAA4B);
  final darkText = const Color(0xFF222222);
  final chipGreen = const Color(0xFF2F9E44);

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: primaryGreen, width: 1.4),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(
          text,
          textAlign: TextAlign.left,
          style: TextStyle(
            fontSize: 18,
            color: darkText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    plateCtrl.dispose();
    provinceCtrl.dispose();
    brandCtrl.dispose();
    ownerCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bg,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () {},
        ),
        centerTitle: true,
        title: Column(
          children: [
            const Icon(
              Icons.directions_car_filled,
              size: 42,
              color: Colors.black87,
            ),
            const SizedBox(height: 6),
            Text(
              'แก้ไขข้อมูล',
              style: TextStyle(
                color: primaryGreen,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        toolbarHeight: 110,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // << ชิดซ้ายคอลัมน์หลัก
              children: [
                _sectionTitle('ข้อมูลทะเบียนรถ'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: plateCtrl,
                        decoration: _fieldDecoration('หมายเลขทะเบียนรถ'),
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'กรอกหมายเลขทะเบียน'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: provinceCtrl,
                        decoration: _fieldDecoration('จังหวัดป้ายทะเบียน'),
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'กรอกจังหวัด'
                            : null,
                      ),
                    ),
                  ],
                ),

                _sectionTitle('ข้อมูลประเภทรถ'),
                TextFormField(
                  controller: brandCtrl,
                  decoration: _fieldDecoration('ยี่ห้อรถยนต์'),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'กรอกยี่ห้อรถ' : null,
                ),

                _sectionTitle('ข้อมูลเจ้าของรถ'),
                TextFormField(
                  controller: ownerCtrl,
                  decoration: _fieldDecoration('ชื่อผู้ขับขี่/เจ้าของรถ'),
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'กรอกชื่อผู้ขับขี่/เจ้าของรถ'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: _fieldDecoration('เบอร์ติดต่อ'),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'กรอกเบอร์ติดต่อ';
                    if (v.replaceAll(' ', '').length < 9)
                      return 'เบอร์ไม่ถูกต้อง';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: emailCtrl,
                  decoration: _fieldDecoration('Email'),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'กรอกอีเมล';
                    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v);
                    return ok ? null : 'รูปแบบอีเมลไม่ถูกต้อง';
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: passwordCtrl,
                  decoration: _fieldDecoration('Password'),
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 6)
                      ? 'อย่างน้อย 6 ตัวอักษร'
                      : null,
                ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: Colors.orange.shade400,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          backgroundColor: Colors.orange.shade300,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('เข้าสู่โหมดแก้ไข')),
                          );
                        },
                        child: const Text(
                          'แก้ไข',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          backgroundColor: chipGreen,
                          foregroundColor: Colors.white,
                          elevation: 1.5,
                        ),
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('บันทึกข้อมูลเรียบร้อย'),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'บันทึก',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// สำหรับทดสอบอย่างรวดเร็ว ให้ใช้ไฟล์นี้เป็น main ได้เลย
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Edit Car',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFEFFBEF),
        useMaterial3: true,
      ),
      home: const EditCarPage(),
    );
  }
}
