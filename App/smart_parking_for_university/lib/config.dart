import 'dart:io' show Platform;

class AppConfig {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return "http://10.0.2.2:3000/";
    } else {
      // iOS, desktop ฯลฯ ใช้ localhost ได้ตรงๆ
      return "http://localhost:3000/";
    }
  }

  static String get baseApiUrl {
    if (Platform.isAndroid) {
      return "http://10.0.2.2:3000/api/v1";
    } else {
      return "http://localhost:3000/api/v1";
    }
  }
}
