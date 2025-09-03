import 'package:flutter/material.dart';
import 'package:smart_parking_for_university/components/menu.dart';
import 'package:smart_parking_for_university/models/slot_status.dart';
import 'package:smart_parking_for_university/pages/dashboard.dart';
import 'package:smart_parking_for_university/pages/parkingbooking.dart';
import 'package:smart_parking_for_university/services/api_service.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _api = ApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Dummy data for fallback
  final List<Map<String, dynamic>> dummySlots = [
    {"slot_number": 1, "slot_name": "1", "status": "FREE"},
    {"slot_number": 2, "slot_name": "2", "status": "FREE"},
    {"slot_number": 3, "slot_name": "3", "status": "OCCUPIED"},
    {"slot_number": 4, "slot_name": "4", "status": "RESERVED"},
    {"slot_number": 5, "slot_name": "5", "status": "DISABLED"},
  ];

  List<Map<String, dynamic>> slots = [];
  int? selectedSlot;
  int? slot_number;
  bool reserving = false;
  @override
  void initState() {
    super.initState();
    fetchSlots();
  }

  // 2) ใช้ items ให้ถูก + เคลียร์ selection ให้ปลอดภัย
  Future<void> fetchSlots() async {
    try {
      final res = await _api.getSlotsStatus();
      final items = res['items'];

      if (items is List && items.isNotEmpty) {
        setState(() {
          slots = List<Map<String, dynamic>>.from(items);
          final outOfRange =
              selectedSlot == null ||
              selectedSlot! < 0 ||
              selectedSlot! >= slots.length;
          final statusOk =
              !outOfRange &&
              SlotStatusX.fromString(slots[selectedSlot!]['status'] ?? '') ==
                  SlotStatus.free;
          if (!statusOk) selectedSlot = null;
        });
      } else {
        setState(() {
          slots = dummySlots;
          selectedSlot = null;
        });
      }
    } catch (_) {
      setState(() {
        slots = dummySlots;
        selectedSlot = null;
      });
    }
  }

  void showCustomPopup(bool isBooking, {String? accessCode}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFFE0FBDB),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFD5FCD5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isBooking ? "จองที่จอดสำเร็จ" : "ยกเลิกที่จอดรถ",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isBooking ? Colors.green : Colors.red,
                      ),
                    ),
                    if (isBooking && (accessCode?.isNotEmpty ?? false)) ...[
                      const SizedBox(height: 8),
                      Text(
                        "รหัสเข้า: ${accessCode!}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                isBooking ? Icons.directions_car : Icons.cancel,
                color: isBooking ? Colors.green : Colors.red,
                size: 40,
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool isSlotAvailable(String status) =>
      SlotStatusX.fromString(status) == SlotStatus.free;

  Widget parkingSlot(int index) {
    if (index < 0 || index >= slots.length) return const SizedBox.shrink();
    final slot = slots[index];
    final statusStr = slot['status']?.toString() ?? 'DISABLED';
    final status = SlotStatusX.fromString(statusStr);

    final available =
        status == SlotStatus.free || status == SlotStatus.reserved;
    final isSelected = selectedSlot == index;

    return GestureDetector(
      onTap: available
          ? () {
              print(slot);
              setState(() {
                selectedSlot = index;
                final sn = slot['slot_number'];
                if (sn is int) {
                  slot_number = sn;
                } else if (sn is String) {
                  slot_number = int.tryParse(sn);
                } else {
                  slot_number = null;
                }
              });
            }
          : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? Colors.green : Colors.green.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("ช่องจอดรถที่ ${slot['slot_name'] ?? (index + 1)}"),
            Row(
              children: [
                Text(
                  status.thai,
                  style: TextStyle(
                    color: status.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.circle, size: 16, color: status.color),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canBook =
        selectedSlot != null &&
        slots.isNotEmpty &&
        (isSlotAvailable(slots[selectedSlot!]["status"] ?? "") ||
            SlotStatusX.fromString(slots[selectedSlot!]["status"] ?? "") ==
                SlotStatus.reserved);
    final bool isReserved =
        selectedSlot != null &&
        slots.isNotEmpty &&
        SlotStatusX.fromString(slots[selectedSlot!]["status"] ?? "") ==
            SlotStatus.reserved;
    final bool canCancel = selectedSlot != null && slots.isNotEmpty;

    return Scaffold(
      key: _scaffoldKey,
      drawer: hamburger(context),
      backgroundColor: const Color(0xFFE0FBDB),
      body: Column(
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
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                const Spacer(),
              ],
            ),
          ),
          const Icon(
            Icons.directions_car,
            size: 60,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
          const SizedBox(height: 8),
          const Text(
            "จองที่จอด",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchSlots,
              child: slots.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 200),
                        Center(child: CircularProgressIndicator()),
                        SizedBox(height: 400), // เผื่อให้ลากได้
                      ],
                    )
                  : ListView.builder(
                      itemCount: slots.length,
                      itemBuilder: (context, index) => parkingSlot(index),
                    ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                onPressed: (canBook && !reserving)
                    ? () async {
                        if (isReserved) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ParkingBookingPage(slotNumber: slot_number),
                            ),
                          );
                        } else {
                          if (slot_number == null) return;
                          setState(() => reserving = true);
                          try {
                            final res = await _api.reserveSlot(slot_number!);
                            final failed =
                                res is Map && (res['success'] == false);
                            if (!failed) {
                              final accessCode = (res['access_code'] ??
                                      res['data']?['access_code'] ??
                                      res['reservation']?['access_code'])
                                  ?.toString();
                              showCustomPopup(true, accessCode: accessCode);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ParkingBookingPage(
                                      slotNumber: slot_number),
                                ),
                              );
                            } else {
                              final msg = res['data']?['message'] ??
                                  res['message'] ??
                                  'จองไม่สำเร็จ';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(msg.toString())),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          } finally {
                            await fetchSlots();
                            if (mounted) setState(() => reserving = false);
                          }
                        }
                      }
                    : null,
                child: Text(
                  reserving ? "กำลังจอง..." : (isReserved ? "ดู" : "จอง"),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                onPressed: canCancel ? () => showCustomPopup(false) : null,
                child: const Text("ยกเลิก"),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
