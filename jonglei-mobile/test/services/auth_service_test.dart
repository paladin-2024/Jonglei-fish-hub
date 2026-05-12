import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:jonglei_fish_hub/models/user.dart';
import 'package:jonglei_fish_hub/services/api_service.dart';
import 'package:jonglei_fish_hub/services/auth_service.dart';
import 'package:jonglei_fish_hub/services/storage_service.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────────

class _FakeStorage implements StorageService {
  final Map<String, String> _store = {};

  @override
  Future<void> saveTokens(
      {required String accessToken, required String refreshToken}) async {
    _store['access_token'] = accessToken;
    _store['refresh_token'] = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => _store['access_token'];

  @override
  Future<String?> getRefreshToken() async => _store['refresh_token'];

  @override
  Future<void> saveUser(User user) async {
    _store['user'] = jsonEncode(user.toJson());
  }

  @override
  Future<User?> getUser() async {
    final raw = _store['user'];
    if (raw == null) return null;
    return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> clearAll() async => _store.clear();

  @override
  Future<void> setString(String key, String value) async =>
      _store[key] = value;

  @override
  Future<String?> getString(String key) async => _store[key];
}

final _sampleUserJson = {
  'id': 'user-uuid-001',
  'phone_number': '+211912000001',
  'username': 'testbuyer',
  'role': 'BUYER',
  'role_display': 'Buyer',
  'location': 'Juba',
  'is_verified': false,
  'rating': '0.0',
  'total_transactions': 0,
  'preferred_language': 'EN',
};

final _sampleLoginResponse = {
  'access_token': 'access-xyz',
  'refresh_token': 'refresh-abc',
  'user': _sampleUserJson,
};

class _FakeApi implements ApiService {
  Map<String, dynamic>? _loginResponse;
  Map<String, dynamic>? _registerResponse;
  bool throwOnLogin = false;
  String? lastPostPath;
  bool? lastPostRequiresAuth;

  _FakeApi();

  @override
  Future<dynamic> post(String path, Map<String, dynamic> body,
      {bool requiresAuth = true}) async {
    lastPostPath = path;
    lastPostRequiresAuth = requiresAuth;
    if (throwOnLogin) throw const ApiException(400, 'Invalid credentials');
    if (path.contains('login')) return _loginResponse ?? _sampleLoginResponse;
    if (path.contains('register')) {
      return _registerResponse ?? _sampleLoginResponse;
    }
    return {};
  }

  @override
  Future<dynamic> get(String path) async => {};

  @override
  Future<List<dynamic>> getList(String path) async => [];

  @override
  Future<dynamic> patch(String path, Map<String, dynamic> body,
      {bool requiresAuth = true}) async => {};

  @override
  Future<dynamic> delete(String path) async => {};

  @override
  Future<dynamic> postMultipart(String path,
      {required File file,
      required String fileField,
      Map<String, String> fields = const {}}) async => {};

  @override
  Future<dynamic> postMultipartFields(String path, Map<String, String> fields,
      {File? photoFile, String photoField = 'photo'}) async => {};
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late _FakeStorage storage;
  late _FakeApi api;
  late AuthService auth;

  setUp(() {
    storage = _FakeStorage();
    api = _FakeApi();
    auth = AuthService(api, storage);
  });

  group('AuthService.login', () {
    test('saves access and refresh tokens on success', () async {
      await auth.login(
          phoneNumber: '+211912000001', password: 'pass123');
      expect(await storage.getAccessToken(), 'access-xyz');
      expect(await storage.getRefreshToken(), 'refresh-abc');
    });

    test('returns correct User on success', () async {
      final user = await auth.login(
          phoneNumber: '+211912000001', password: 'pass123');
      expect(user.id, 'user-uuid-001');
      expect(user.role, 'BUYER');
      expect(user.username, 'testbuyer');
    });

    test('persists user to storage', () async {
      await auth.login(
          phoneNumber: '+211912000001', password: 'pass123');
      final stored = await storage.getUser();
      expect(stored?.id, 'user-uuid-001');
    });

    test('throws ApiException on bad credentials', () async {
      api.throwOnLogin = true;
      expect(
        () => auth.login(
            phoneNumber: '+211912000001', password: 'wrong'),
        throwsA(isA<ApiException>()),
      );
    });

    test('login posts to /auth/login/ without requiresAuth', () async {
      await auth.login(
          phoneNumber: '+211912000001', password: 'pass123');
      expect(api.lastPostPath, contains('login'));
      expect(api.lastPostRequiresAuth, false);
    });
  });

  group('AuthService.register', () {
    test('register posts to /auth/register/ without requiresAuth', () async {
      await auth.register(
        phoneNumber: '+211912000002',
        username: 'newuser',
        password: 'pass123',
        role: 'TRADER',
      );
      expect(api.lastPostPath, contains('register'));
      expect(api.lastPostRequiresAuth, false);
    });

    test('saves tokens after register', () async {
      await auth.register(
        phoneNumber: '+211912000002',
        username: 'newuser',
        password: 'pass123',
        role: 'TRADER',
      );
      expect(await storage.getAccessToken(), 'access-xyz');
    });
  });

  group('AuthService.logout', () {
    test('clears all stored data', () async {
      await auth.login(
          phoneNumber: '+211912000001', password: 'pass123');
      await auth.logout();
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(await storage.getUser(), isNull);
    });
  });

  group('AuthService.getCurrentUser', () {
    test('returns null when not logged in', () async {
      final user = await auth.getCurrentUser();
      expect(user, isNull);
    });

    test('returns saved user after login', () async {
      await auth.login(
          phoneNumber: '+211912000001', password: 'pass123');
      final user = await auth.getCurrentUser();
      expect(user?.id, 'user-uuid-001');
    });
  });
}
