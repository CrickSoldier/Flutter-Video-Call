import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import flutter_dotenv
import '../models/user.dart';

class ApiService {
  final String _baseUrl = 'https://reqres.in/api';

  Future<bool> login(String email, String password) async {
    final apiKey =
        dotenv.env['API_KEY'] ?? 'default-api-key'; // Fallback if not found
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json', 'x-api-key': apiKey},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Invalid credentials');
    }
  }

  Future<List<User>> fetchUsers() async {
    final apiKey =
        dotenv.env['API_KEY'] ?? 'default-api-key'; // Fallback if not found
    final response = await http.get(
      Uri.parse('$_baseUrl/users'),
      headers: {'x-api-key': apiKey},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'] as List;
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }
}
