import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class User {
  final int id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? notes;
  final String status;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.notes,
    required this.status,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      notes: json['notes'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'notes': notes,
      'status': status,
    };
  }
}

class AuthService {
  final String baseUrl = 'http://192.168.0.101:8090/api';

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save auth token if it exists in the response
        if (responseData['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', responseData['token']);

          // Save user data if it exists
          if (responseData['user'] != null) {
            final user = User.fromJson(responseData['user']);
            await prefs.setString('user_data', jsonEncode(user.toJson()));
          }
        }
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Login failed. Please try again.'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error. Please try again.'};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') != null;
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');

    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }

    return null;
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phoneNumber,
    String? notes,
  }) async {
    try {
      final token = await _getAuthToken();

      final response = await http.post(
        Uri.parse('$baseUrl/profile/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'phone_number': phoneNumber,
          'notes': notes ?? '',
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Update stored user data
        if (responseData['user'] != null) {
          final user = User.fromJson(responseData['user']);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(user.toJson()));
        }

        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please try again.',
      };
    }
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
