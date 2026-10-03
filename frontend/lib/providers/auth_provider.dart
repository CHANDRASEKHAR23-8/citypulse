import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService apiService;

  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({required this.apiService});

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _currentUser != null && _token != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isCitizen => _currentUser?.isCitizen ?? false;
  bool get isOfficer => _currentUser?.isOfficer ?? false;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  Future<bool> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      final savedToken = await StorageService.getToken();
      final savedUser = await StorageService.getUser();

      if (savedToken != null && savedUser != null) {
        _token = savedToken;
        _currentUser = savedUser;
        apiService.setToken(savedToken);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {
      // Fallback
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await apiService.login(email.trim(), password.trim());
      _token = res['token'] as String;
      _currentUser = res['user'] as User;
      await StorageService.saveSession(_token!, _currentUser!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String role = 'citizen',
    String? department,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await apiService.register(
        name: name.trim(),
        email: email.trim(),
        password: password.trim(),
        role: role,
        department: department,
      );
      _token = res['token'] as String;
      _currentUser = res['user'] as User;
      await StorageService.saveSession(_token!, _currentUser!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _token = null;
    apiService.setToken(null);
    await StorageService.clearSession();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
