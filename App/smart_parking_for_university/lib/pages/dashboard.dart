import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:smart_parking_for_university/components/menu.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_parking_for_university/services/api_service.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  // เพิ่มการประกาศ _scaffoldKey ที่ขาดหายไป
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final _api = ApiService();

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

  // ข้อมูลสำหรับรายการที่จอดรถ (อัปเดตจาก API)
  List<Map<String, dynamic>> parkingData = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final res = await _api.getDashboard();
      // Weekly statistics
      final stats = res['weekly_statistics'];
      if (stats is Map) {
        final x = (stats['x_axis'] as List?) ?? const [];
        final v = (stats['values'] as List?) ?? const [];
        setState(() {
          weeklyData.clear();
          for (int i = 0; i < x.length; i++) {
            final day = x[i].toString();
            final raw = i < v.length ? v[i] : 0;
            final val = raw is num ? raw.toInt() : int.tryParse(raw.toString()) ?? 0;
            weeklyData[day] = val;
          }
        });
      }

      // Parking spaces
      final spaces = res['parking_spaces'];
      if (spaces is List) {
        setState(() {
          parkingData = List<Map<String, dynamic>>.from(
            spaces.map((e) {
              final name = e['slot_name']?.toString() ?? e['slot_number']?.toString() ?? '';
              final cars = (e['cars'] is num)
                  ? (e['cars'] as num).toInt()
                  : int.tryParse(e['cars']?.toString() ?? '0') ?? 0;
              return {
                'space': 'ช่องจอดรถที่ $name',
                'cars': cars,
              };
            }),
          );
        });
      } else {
        setState(() {
          parkingData = [];
        });
      }
    } catch (_) {
      // เงียบๆ แต่ยังคง state เดิมไว้
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: hamburger(context),
      backgroundColor: const Color(0xFFE0FBDB),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
          // Bar Chart (ใช้ fl_chart) พร้อมแกน Y และกำหนดเพดาน = ค่าสูงสุด
          SizedBox(
            height: 220,
            child: Builder(
              builder: (_) {
                final labels = weeklyData.keys.toList();
                final values = labels.map((k) => (weeklyData[k] ?? 0).toDouble()).toList();
                double maxY = values.isEmpty
                    ? 1
                    : values.reduce((a, b) => math.max(a, b));
                if (maxY <= 0) maxY = 1;

                final groups = <BarChartGroupData>[];
                for (int i = 0; i < values.length; i++) {
                  groups.add(
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i],
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                          color: _green,
                        ),
                      ],
                    ),
                  );
                }

                double interval;
                if (maxY <= 5) {
                  interval = 1;
                } else if (maxY <= 10) {
                  interval = 2;
                } else {
                  interval = (maxY / 5).ceilToDouble();
                }

                return BarChart(
                  BarChartData(
                    maxY: maxY,
                    minY: 0,
                    alignment: BarChartAlignment.spaceAround,
                    barTouchData: BarTouchData(enabled: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: interval,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.black12,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        left: BorderSide(color: Colors.black26),
                        bottom: BorderSide(color: Colors.black26),
                        right: BorderSide(color: Colors.transparent),
                        top: BorderSide(color: Colors.transparent),
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                labels[i],
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          interval: interval,
                          getTitlesWidget: (value, meta) {
                            // แสดงเฉพาะค่าที่หารด้วย interval ลงตัว
                            if ((value % interval).abs() > 0.0001 && value != maxY) {
                              return const SizedBox.shrink();
                            }
                            final isTop = (value - maxY).abs() < 0.0001;
                            final text = value == value.roundToDouble()
                                ? value.toInt().toString()
                                : value.toStringAsFixed(1);
                            return Padding(
                              padding: EdgeInsets.only(right: isTop ? 0 : 6),
                              child: Text(
                                text,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isTop ? FontWeight.w700 : FontWeight.w400,
                                  color: isTop ? Colors.black87 : Colors.black54,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: groups,
                  ),
                );
              },
            ),
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
