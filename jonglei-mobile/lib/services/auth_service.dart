import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _api;
  final StorageService _storage;

  AuthService(this._api, this._storage);

  Future<User> register({
    required String phoneNumber,
    required String username,
    required String password,
    required String role,
    String location = '',
    String preferredLanguage = 'EN',
  }) async {
    final data = await _api.post('/auth/register/', {
      'phone_number': phoneNumber,
      'username': username,
      'password': password,
      'role': role,
      'location': location,
      'preferred_language': preferredLanguage,
    });
    return _saveSession(data as Map<String, dynamic>);
  }

  Future<User> login({
    required String phoneNumber,
    required String password,
  }) async {
    final data = await _api.post('/auth/login/', {
      'phone_number': phoneNumber,
      'password': password,
    });
    return _saveSession(data as Map<String, dynamic>);
  }

  Future<User> _saveSession(Map<String, dynamic> data) async {
    await _storage.saveTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    await _storage.saveUser(user);
    return user;
  }

  Future<void> logout() => _storage.clearAll();

  Future<User?> getCurrentUser() => _storage.getUser();
}
