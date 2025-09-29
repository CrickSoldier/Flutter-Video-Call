import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    try {
      debugPrint('Loading SharedPreferences for auth state');
      final prefs = await SharedPreferences.getInstance();
      _isAuthenticated = prefs.getBool('isLoggedIn') ?? false;
      debugPrint('Auth state loaded: isAuthenticated=$_isAuthenticated');
    } catch (e) {
      errorMessage = 'Failed to load auth state: $e';
      debugPrint('Load auth state error: $e');
      _isAuthenticated = false; // Fallback to false
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Attempting login with email: $email');
      final success = await ApiService().login(email, password);
      debugPrint('Login API result: $success');
      if (success) {
        _isAuthenticated = true;
        try {
          debugPrint('Saving isLoggedIn to SharedPreferences');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          debugPrint('isLoggedIn saved successfully');
        } catch (e) {
          debugPrint('Failed to save auth state: $e');
          // Fallback: Continue login without saving to SharedPreferences
          errorMessage =
              'Authentication succeeded, but failed to save state: $e';
        }
      } else {
        errorMessage = 'Login failed: Invalid credentials';
      }
      isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      errorMessage = 'Login failed: $e';
      debugPrint('Login error: $e');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    errorMessage = null;
    try {
      debugPrint('Clearing isLoggedIn from SharedPreferences');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      debugPrint('isLoggedIn cleared successfully');
    } catch (e) {
      errorMessage = 'Failed to clear auth state: $e';
      debugPrint('Clear auth state error: $e');
    }
    notifyListeners();
  }
}
