import 'package:flutter/material.dart';
import 'package:smart_parking_for_university/pages/dashboard.dart';
import 'package:smart_parking_for_university/pages/edit_page.dart';
import 'package:smart_parking_for_university/pages/home.dart';
import 'package:smart_parking_for_university/pages/login_page.dart';
import 'package:smart_parking_for_university/pages/parkingbooking.dart';
import 'package:smart_parking_for_university/pages/registor_page.dart';
import 'package:smart_parking_for_university/pages/parkingbooking.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/login",
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
