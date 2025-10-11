import 'dart:io' show Platform;

const String _defaultHost =
    String.fromEnvironment('BACKEND_HOST', defaultValue: '172.16.9.152');
const String _androidHost =
    String.fromEnvironment('ANDROID_HOST', defaultValue: '10.0.2.2');
const int _backendPort =
    int.fromEnvironment('BACKEND_PORT', defaultValue: 3000);
const String _scheme =
    String.fromEnvironment('BACKEND_SCHEME', defaultValue: 'http');

Uri _buildBaseUri(String host, {String path = '/'}) =>
    Uri(scheme: _scheme, host: host, port: _backendPort, path: path);

class AppConfig {
  static Uri get baseUri =>
      Platform.isAndroid ? _buildBaseUri(_androidHost) : _buildBaseUri(_defaultHost);

  static Uri get baseApiUri => baseUri.replace(path: 'api/v1');

  static String get baseUrl => baseUri.toString();

  static String get baseApiUrl => baseApiUri.toString();
}
