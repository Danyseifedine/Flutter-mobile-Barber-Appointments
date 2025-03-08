import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sys/models/appointment.dart';

class ServiceService {
  final String baseUrl = 'http://192.168.0.101:8090/api';

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<List<Service>> getServices() async {
    try {
      final token = await _getAuthToken();

      final response = await http.get(
        Uri.parse('http://192.168.0.101:8090/api/services'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          final List<dynamic> servicesJson = responseData['data'];
          return servicesJson.map((json) => Service.fromJson(json)).toList();
        } else {
          print('API returned success=false or no data: ${response.body}');
        }
      } else {
        print('API error with status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      return [];
    } catch (e) {
      print('Error fetching services: $e');
      return [];
    }
  }
}
