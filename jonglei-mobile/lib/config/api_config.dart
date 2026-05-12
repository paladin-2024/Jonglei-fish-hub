class ApiConfig {
  // ── Dev: physical device on same WiFi ──────────────────────────────────────
  // Run: ip addr show | grep 'inet ' | grep -v 127 to get your machine's IP
  // Then replace the IP below.
  static const String baseUrl = 'http://192.168.1.161:8000/api/v1';


  // ── Alternatives ───────────────────────────────────────────────────────────
  // Android emulator:       'http://10.0.2.2:8000/api/v1'
  // iOS simulator:          'http://127.0.0.1:8000/api/v1'
  // Production:             'https://api.jonglei.app/api/v1'
}