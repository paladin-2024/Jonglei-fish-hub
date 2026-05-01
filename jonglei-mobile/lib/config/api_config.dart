class ApiConfig {
  // Android emulator routes 10.0.2.2 to the host machine's localhost
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
  // For iOS simulator or physical device on the same WiFi, use your machine's LAN IP:
  // static const String baseUrl = 'http://192.168.x.x:8000/api/v1';
}
