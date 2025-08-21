import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_parking_for_university/services/api_service.dart';

class ParkingBookingPage extends StatefulWidget {
  const ParkingBookingPage({super.key});

  @override
  State<ParkingBookingPage> createState() => _ParkingBookingPageState();
}

class _ParkingBookingPageState extends State<ParkingBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();

  final _nameCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  final _green = const Color(0xFF2EB94C); // เขียวหลักของเส้นขอบ/หัวเรื่อง
  final _bgLight = const Color(0xFFE9FBE9); // พื้นหลังเขียวอ่อน

  @override
  void dispose() {
    _nameCtrl.dispose();
    _timeCtrl.dispose();
    _plateCtrl.dispose();
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  InputDecoration _input(String hint) {
    final radius = BorderRadius.circular(18);
    final border = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: _green, width: 1.5),
    );
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: _green, width: 2),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      initialDate: now,
      locale: const Locale('th'),
    );
    if (d == null) return;

    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (t == null) return;

    final dt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    _timeCtrl.text = DateFormat('dd/MM/yyyy HH:mm', 'th').format(dt);
    setState(() {});
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      // ทำสิ่งที่ต้องการต่อ เช่น ส่งข้อมูลไป backend หรือแสดง dialog ยืนยัน
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกข้อมูลการจองเรียบร้อย')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: _bgLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.black87,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Icon(Icons.directions_car, size: 56, color: Colors.black87),
            const SizedBox(height: 8),
            Text(
              'จองที่จอด',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: _green,
              ),
            ),
            const SizedBox(height: 24),
            // การ์ดฟอร์ม
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('ผู้จอง'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: _input('เช่น สมชาย ใจดี'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'กรุณากรอกชื่อผู้จอง'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // แถว: เวลาที่จอง + ป้ายทะเบียน
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('เวลาที่จอง'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _timeCtrl,
                                readOnly: true,
                                onTap: _pickDateTime,
                                decoration: _input('เลือกวัน-เวลา'),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'กรุณาเลือกเวลา'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('ป้ายทะเบียน'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _plateCtrl,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: _input('เช่น กก 1234'),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'กรุณากรอกป้ายทะเบียน'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _label('เบอร์ติดต่อ'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: _input('เช่น 0812345678'),
                      validator: (v) {
                        final x = v?.replaceAll(' ', '') ?? '';
                        if (x.isEmpty) return 'กรุณากรอกเบอร์ติดต่อ';
                        if (x.length < 9) return 'กรุณากรอกเบอร์ให้ถูกต้อง';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    _label('รหัสที่จอง'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _codeCtrl,
                      decoration: _input('กำหนดรหัสสำหรับการจอง'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'กรุณากรอกรหัส'
                          : null,
                    ),
                    const SizedBox(height: 24),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: Colors.black87,
    ),
  );
}
