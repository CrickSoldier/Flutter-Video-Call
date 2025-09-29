import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class UserProvider with ChangeNotifier {
  List<User> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  UserProvider() {
    _loadCachedUsers(); // Load cached users on initialization
  }

  Future<void> fetchUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final users = await ApiService().fetchUsers();
      _users = users;
      await _cacheUsers(users);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch users: ${e.toString()}';
      await _loadCachedUsers(); // Fallback to cached data
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _cacheUsers(List<User> users) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = users.map((user) => jsonEncode(user.toJson())).toList();
    await prefs.setStringList('users', userData);
  }

  Future<void> _loadCachedUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getStringList('users');
    if (userData != null) {
      _users = userData.map((data) => User.fromJson(jsonDecode(data))).toList();
      notifyListeners();
    }
  }
}
