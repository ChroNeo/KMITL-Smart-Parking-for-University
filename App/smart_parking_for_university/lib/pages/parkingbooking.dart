import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_parking_for_university/services/api_service.dart';
import 'package:smart_parking_for_university/models/slot_status.dart';

class ParkingBookingPage extends StatefulWidget {
  final int? slotNumber;
  const ParkingBookingPage({super.key, required this.slotNumber});

  @override
  State<ParkingBookingPage> createState() => _ParkingBookingPageState();
}

class _ParkingBookingPageState extends State<ParkingBookingPage> {
  final _api = ApiService();
  Map<String, dynamic>? reservation;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchReservation();
  }

  Future<void> fetchReservation() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      if (widget.slotNumber == null) {
        setState(() {
          error = "ไม่พบหมายเลขช่องจอด";
          loading = false;
        });
        return;
      }
      final res = await _api.getReservationBySlot(widget.slotNumber!);
      if (res['success'] == true) {
        setState(() {
          reservation = res['data'];
          loading = false;
        });
      } else {
        setState(() {
          reservation = res['data'];
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  final _green = const Color(0xFF2EB94C); // เขียวหลักของเส้นขอบ/หัวเรื่อง
  final _bgLight = const Color(0xFFE9FBE9); // พื้นหลังเขียวอ่อน

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
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Icon(Icons.directions_car, size: 56, color: Colors.black87),
                  const SizedBox(height: 8),
                  Text(
                    'จองที่จอดรถช่อง ${widget.slotNumber}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: _green,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: reservation == null
                        ? const SizedBox()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // If not your slot
                              if (reservation!['message'] != null) ...[
                                Text(
                                  reservation!['message'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _label('ช่องจอด'),
                                _value(
                                  reservation!['slot_name'] ??
                                      reservation!['slot_number'] ??
                                      '-',
                                ),
                                const SizedBox(height: 12),
                                _label('สถานะ'),
                                _value(
                                  reservation!['reservation_status'] ?? '-',
                                ),
                                const SizedBox(height: 12),
                                _label('จองถึง'),
                                _value(
                                  reservation!['reserved_until'],
                                  isDate: true,
                                ),
                              ] else ...[
                                _label('ช่องจอด'),
                                _value(
                                  reservation!['slot_name'] ??
                                      reservation!['slot_number'] ??
                                      '-',
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _label('ผู้จอง'),
                                        _value(
                                          reservation!['full_name'] ?? '-',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 25),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _label('ป้ายทะเบียน'),
                                        _value(
                                          reservation!['car_registration'] ??
                                              '-',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                _label('รหัสเข้า'),
                                _value(reservation!['access_code'] ?? '-'),
                                const SizedBox(height: 12),
                                _label('เวลาที่จอง'),
                                _value(
                                  reservation!['created_at'],
                                  isDate: true,
                                ),
                                const SizedBox(height: 12),
                                _label('หมดอายุ'),
                                _value(
                                  reservation!['expires_at'],
                                  isDate: true,
                                ),
                                const SizedBox(height: 12),
                                _label('เบอร์ติดต่อ'),
                                _value(reservation!['phone_number'] ?? '-'),
                                const SizedBox(height: 12),
                                _label('สถานะ'),
                                _value(
                                  ReservStatusX.fromString(
                                    reservation!['reservation_status'] ?? '-',
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    try {
      final dt = DateTime.parse(value.toString()).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return value.toString();
    }
  }

  Widget _label(String text) => Text(
    text,
    style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 16),
  );

  Widget _value(dynamic value, {bool isDate = false}) => Padding(
    padding: const EdgeInsets.only(top: 2, bottom: 8),
    child: Text(
      isDate ? _formatDate(value) : (value?.toString() ?? '-'),
      style: const TextStyle(
        fontSize: 18,
        color: Colors.black87,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
