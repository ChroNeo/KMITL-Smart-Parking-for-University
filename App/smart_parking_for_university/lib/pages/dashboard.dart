import 'package:flutter/material.dart';
import 'package:smart_parking_for_university/components/menu.dart';
// import 'package:fl_chart/fl_chart.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  // เพิ่มการประกาศ _scaffoldKey ที่ขาดหายไป
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // กำหนดสีที่จะใช้
  final Color _bgLight = const Color(0xFFE0FBDB);
  final Color _green = const Color(0xFF4CAF50);

  // ข้อมูลจำลองสำหรับ Weekly Statistics
  final Map<String, int> weeklyData = {
    'Mon': 0,
    'Tue': 0,
    'Wed': 0,
    'Thu': 0,
    'Fri': 0,
    'Sat': 0,
    'Sun': 0,
  };

  // ข้อมูลจำลองสำหรับรายการที่จอดรถ
  final List<Map<String, dynamic>> parkingData = [
    {'space': 'ช่องจอดรถที่ 1', 'cars': 0},
    {'space': 'ช่องจอดรถที่ 2', 'cars': 0},
    {'space': 'ช่องจอดรถที่ 3', 'cars': 0},
    {'space': 'ช่องจอดรถที่ 4', 'cars': 0},
    {'space': 'ช่องจอดรถที่ 5', 'cars': 0},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: hamburger(context),
      backgroundColor: const Color(0xFFE0FBDB),
      body: SingleChildScrollView(
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
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            // เนื้อหาส่วนนี้ถูกย้ายเข้ามาใน SingleChildScrollView
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.directions_car,
                          size: 56,
                          color: Colors.black87,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dashboard',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: _green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Weekly Statistics Card
                  _buildStatisticsCard(),
                  const SizedBox(height: 24),
                  // Parking Space Card
                  _buildParkingCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Weekly Statistics",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          // Bar Chart (กราฟแท่ง)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: weeklyData.entries.map((entry) {
              return _buildBar(entry.key, entry.value, _green);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String day, int value, Color color) {
    // คำนวณความสูงของ Bar โดยเทียบกับค่าสูงสุด (100)
    final double barHeight = (value / 100) * 100;

    return Column(
      children: [
        SizedBox(
          width: 20,
          height: 100,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: barHeight,
              width: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  /// ====== ส่วนที่แก้ให้เป็น "แคปซูลขอบเขียว" ======
  Widget _buildParkingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Parking Space",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              Text(
                "Number of Car",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: parkingData.length,
            itemBuilder: (context, index) {
              final item = parkingData[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _green, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item['space'], style: const TextStyle(fontSize: 16)),
                      Text(
                        '${item['cars']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}