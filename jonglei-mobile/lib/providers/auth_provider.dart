import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  User? _currentUser;
  bool _loading = false;
  String? _errorMessage;

  AuthProvider(this._authService);

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  Future<void> checkAuthStatus() async {
    _currentUser = await _authService.getCurrentUser();
    notifyListeners();
  }

  Future<bool> login(String phoneNumber, String password) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentUser = await _authService.login(
        phoneNumber: phoneNumber,
        password: password,
      );
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String phoneNumber,
    required String username,
    required String password,
    required String role,
    String location = '',
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentUser = await _authService.register(
        phoneNumber: phoneNumber,
        username: username,
        password: password,
        role: role,
        location: location,
      );
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }
}
