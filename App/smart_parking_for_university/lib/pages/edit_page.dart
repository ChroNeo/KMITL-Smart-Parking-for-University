import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:smart_parking_for_university/components/menu.dart';
import 'package:smart_parking_for_university/services/api_service.dart';

class EditCarPage extends StatefulWidget {
  const EditCarPage({super.key});

  @override
  State<EditCarPage> createState() => _EditCarPageState();
}

class _EditCarPageState extends State<EditCarPage> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final _api = ApiService();

  final plateCtrl = TextEditingController();
  final provinceCtrl = TextEditingController();
  final brandCtrl = TextEditingController();
  final ownerCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  bool isEditing = false;
  String? error;

  String? carRegistration;
  String? carProvince;
  String? carBrand;
  String? fullName;
  String? phoneNumber;

  final bg = const Color(0xFFE0FBDB);
  final primaryGreen = const Color(0xFF3BAA4B);
  final darkText = const Color(0xFF222222);
  final chipGreen = const Color(0xFF2F9E44);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ---------- helpers ----------
  String _asString(dynamic v) => (v == null) ? '' : v.toString();

  Map<String, dynamic> _ensureMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is String && v.isNotEmpty) {
      try {
        final decoded = jsonDecode(v);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return <String, dynamic>{};
  }

  Future<void> _loadProfile() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final String? meStr = await _api.getMe();
      final me = meStr == null
          ? <String, dynamic>{}
          : jsonDecode(meStr) as Map<String, dynamic>;
      ;

      setState(() {
        carRegistration = _asString(
          me['car_registration'] ?? me['license_plate'] ?? me['plate'],
        );
        carProvince = _asString(me['car_province'] ?? me['province']);
        carBrand = _asString(me['car_brand'] ?? me['make'] ?? me['brand']);
        fullName = _asString(me['full_name'] ?? me['name'] ?? me['owner']);
        phoneNumber = _asString(me['phone_number'] ?? me['phone'] ?? me['tel']);
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _enterEditMode() {
    plateCtrl.text = carRegistration ?? '';
    provinceCtrl.text = carProvince ?? '';
    brandCtrl.text = carBrand ?? '';
    ownerCtrl.text = fullName ?? '';
    phoneCtrl.text = phoneNumber ?? '';
    setState(() => isEditing = true);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => isSaving = true);
    try {
      final result = await _api.updateMe(
        fullName: ownerCtrl.text.trim(),
        phoneNumber: phoneCtrl.text.trim(),
        carBrand: brandCtrl.text.trim(),
        carRegistration: plateCtrl.text.trim(),
        carProvince: provinceCtrl.text.trim(),
      );

      final ok = (result['success'] == true) || (result['status'] == 200);
      if (!ok) {
        final msg =
            result['data']?['message']?.toString() ??
            'บันทึกไม่สำเร็จ (${result['status']})';
        throw Exception(msg);
      }

      setState(() {
        carRegistration = plateCtrl.text.trim();
        carProvince = provinceCtrl.text.trim();
        carBrand = brandCtrl.text.trim();
        fullName = ownerCtrl.text.trim();
        phoneNumber = phoneCtrl.text.trim();
        isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลเรียบร้อย')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('บันทึกล้มเหลว: $e')));
      }
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  void dispose() {
    plateCtrl.dispose();
    provinceCtrl.dispose();
    brandCtrl.dispose();
    ownerCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: hamburger(context),
      backgroundColor: bg,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? _ErrorBox(message: error!, onRetry: _loadProfile)
            : SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 40,
                        left: 16,
                        right: 16,
                        bottom: 8,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.menu),
                            onPressed: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.directions_car,
                      size: 60,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isEditing ? "แก้ไขข้อมูลรถ" : "ข้อมูลรถของฉัน",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle('ข้อมูลทะเบียนรถ'),
                            isEditing
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: plateCtrl,
                                          decoration: _fieldDecoration(
                                            'หมายเลขทะเบียนรถ',
                                          ),
                                          textInputAction: TextInputAction.next,
                                          validator: (v) =>
                                              (v == null || v.trim().isEmpty)
                                              ? 'กรอกหมายเลขทะเบียน'
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: provinceCtrl,
                                          decoration: _fieldDecoration(
                                            'จังหวัดป้ายทะเบียน',
                                          ),
                                          textInputAction: TextInputAction.next,
                                          validator: (v) =>
                                              (v == null || v.trim().isEmpty)
                                              ? 'กรอกจังหวัด'
                                              : null,
                                        ),
                                      ),
                                    ],
                                  )
                                : _ReadOnlyRow(
                                    leftLabel: 'ทะเบียน',
                                    leftValue: carRegistration ?? '-',
                                    rightLabel: 'จังหวัด',
                                    rightValue: carProvince ?? '-',
                                  ),

                            _sectionTitle('ข้อมูลประเภทรถ'),
                            isEditing
                                ? TextFormField(
                                    controller: brandCtrl,
                                    decoration: _fieldDecoration(
                                      'ยี่ห้อรถยนต์',
                                    ),
                                    textInputAction: TextInputAction.next,
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? 'กรอกยี่ห้อรถ'
                                        : null,
                                  )
                                : _ReadOnlyTile(
                                    label: 'ยี่ห้อ',
                                    value: carBrand ?? '-',
                                  ),

                            _sectionTitle('ข้อมูลเจ้าของรถ'),
                            isEditing
                                ? Column(
                                    children: [
                                      TextFormField(
                                        controller: ownerCtrl,
                                        decoration: _fieldDecoration(
                                          'ชื่อผู้ขับขี่/เจ้าของรถ',
                                        ),
                                        textInputAction: TextInputAction.next,
                                        validator: (v) =>
                                            (v == null || v.trim().isEmpty)
                                            ? 'กรอกชื่อผู้ขับขี่/เจ้าของรถ'
                                            : null,
                                      ),
                                      const SizedBox(height: 10),
                                      TextFormField(
                                        controller: phoneCtrl,
                                        decoration: _fieldDecoration(
                                          'เบอร์ติดต่อ',
                                        ),
                                        keyboardType: TextInputType.phone,
                                        textInputAction: TextInputAction.done,
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) {
                                            return 'กรอกเบอร์ติดต่อ';
                                          }
                                          final d = v.replaceAll(' ', '');
                                          if (d.length < 9) {
                                            return 'เบอร์ไม่ถูกต้อง';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      _ReadOnlyTile(
                                        label: 'เจ้าของ',
                                        value: fullName ?? '-',
                                      ),
                                      _ReadOnlyTile(
                                        label: 'เบอร์ติดต่อ',
                                        value: phoneNumber ?? '-',
                                      ),
                                    ],
                                  ),

                            const SizedBox(height: 24),

                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      side: BorderSide(
                                        color: isEditing
                                            ? Colors.red.shade400
                                            : Colors.orange.shade400,
                                        width: 2,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                      backgroundColor: isEditing
                                          ? Colors.red.shade300
                                          : Colors.orange.shade300,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () {
                                      if (isEditing) {
                                        setState(() => isEditing = false);
                                      } else {
                                        _enterEditMode();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('เข้าสู่โหมดแก้ไข'),
                                          ),
                                        );
                                      }
                                    },
                                    child: Text(
                                      isEditing ? 'ยกเลิก' : 'แก้ไข',
                                      style: const TextStyle(
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
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                      backgroundColor: chipGreen,
                                      foregroundColor: Colors.white,
                                      elevation: 1.5,
                                    ),
                                    // รีเฟรช
                                    onPressed: isSaving
                                        ? null
                                        : (isEditing ? _save : _loadProfile),
                                    child: isSaving
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : Text(
                                            isEditing ? 'บันทึก' : 'รีเฟรช',
                                            style: const TextStyle(
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
                  ],
                ),
              ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: Color(0xFF2F9E44), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: Color(0xFF2F9E44), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: Color(0xFF3BAA4B), width: 1.4),
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
}

// ---------- Widgets อ่านอย่างเดียว ----------
class _ReadOnlyTile extends StatelessWidget {
  final String label;
  final String value;
  const _ReadOnlyTile({required this.label, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2F9E44), width: 1),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;
  const _ReadOnlyRow({
    super.key,
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ReadOnlyTile(label: leftLabel, value: leftValue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ReadOnlyTile(label: rightLabel, value: rightValue),
        ),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBox({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองใหม่'),
            ),
          ],
        ),
      ),
    );
  }
}
