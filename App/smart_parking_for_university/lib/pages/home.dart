import 'package:flutter/material.dart';
import 'package:smart_parking_for_university/pages/dashboard.dart';
import 'package:smart_parking_for_university/pages/parkingbooking.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<bool> isAvailable = [false, true, true, true, true];
  int? selectedSlot;

  void showCustomPopup(bool isBooking) {
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isBooking ? Icons.directions_car : Icons.cancel,
                color: isBooking ? Colors.green : Colors.red,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isBooking ? "จองที่จอดสำเร็จ" : "ยกเลิกที่จอดรถ",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isBooking ? Colors.green : Colors.red,
                  ),
                ),
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

  Widget parkingSlot(int index) {
    bool available = isAvailable[index];
    bool isSelected = selectedSlot == index;

    return GestureDetector(
      onTap: available
          ? () {
              setState(() {
                selectedSlot = index;
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
            Text("ช่องจอดรถที่ ${index + 1}"),
            Row(
              children: [
                Text(
                  available ? "ว่าง" : "ไม่ว่าง",
                  style: TextStyle(
                    color: available ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.circle,
                  size: 16,
                  color: available ? Colors.green : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
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
      ),

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
            child: ListView.builder(
              itemCount: isAvailable.length,
              itemBuilder: (context, index) => parkingSlot(index),
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
                onPressed: selectedSlot != null && isAvailable[selectedSlot!]
                    ? () {
                        showCustomPopup(true);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ParkingBookingPage(),
                          ),
                        );
                      }
                    : null,
                child: const Text("จอง", style: TextStyle(color: Colors.white)),
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
                onPressed: selectedSlot != null
                    ? () => showCustomPopup(false)
                    : null,
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
