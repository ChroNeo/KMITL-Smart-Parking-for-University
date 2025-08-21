import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_parking_for_university/pages/dashboard.dart';
import 'package:smart_parking_for_university/pages/edit_page.dart';
import 'package:smart_parking_for_university/pages/home.dart';
import 'package:smart_parking_for_university/pages/login_page.dart';
import 'package:smart_parking_for_university/pages/parkingbooking.dart';
import 'package:smart_parking_for_university/pages/registor_page.dart';
import 'package:smart_parking_for_university/pages/parkingbooking.dart';
import 'package:smart_parking_for_university/services/api_service.dart';

final _api = ApiService();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final ok = await validateTokenFlow();
  runApp(MainApp(isAuthenticated: ok));
}

Future<bool> validateTokenFlow() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt');
  if (token == null) return false;

  // ชั้นที่ 1: ตรวจหมดอายุจาก payload
  if (JwtDecoder.isExpired(token)) {
    await prefs.remove('jwt');
    return false;
  }

  // ชั้นที่ 2: ยิง /me เพื่อยืนยันกับเซิร์ฟเวอร์
  final ok = await _api.hasJWT(); // อย่าลืม await
  if (!ok) {
    await prefs.remove('jwt');
  }
  return ok;
}

class MainApp extends StatelessWidget {
  final bool isAuthenticated;
  const MainApp({super.key, required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: isAuthenticated ? "/home" : "/login", // Redirect based on authentication
      routes: {
        "/login": (context) => LoginPage(),
        "/registor": (context) => RegistorPage(),
        "/home": (context) => Home(),
        "/dashboard": (context) => Dashboard(),
        "/edit": (context) => EditCarPage(),
        "/parkingbooking": (context) => ParkingBookingPage(),
      },
    );
  }
}
