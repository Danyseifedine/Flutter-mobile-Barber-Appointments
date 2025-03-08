import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sys/models/appointment.dart';

class AppointmentService {
  final String baseUrl = 'http://192.168.0.101:8090/api';
  String? _manualToken; // For manual token setting/testing

  // Manual token setter for debugging
  void setManualToken(String token) {
    _manualToken = token;
    print('Manual token set, length: ${token.length}');
  }

  Future<String?> _getAuthToken() async {
    // First check if we have a manual token set
    if (_manualToken != null && _manualToken!.isNotEmpty) {
      print('Using manually set token (length: ${_manualToken!.length})');
      return _manualToken;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        print('WARNING: No auth token found or token is empty');
        return null;
      } else {
        print('Auth token found in SharedPreferences, length: ${token.length}');
        return token;
      }
    } catch (e) {
      print('Error retrieving auth token: $e');
      return null;
    }
  }

  // A method to check if the token is valid
  Future<bool> isTokenValid() async {
    final token = await _getAuthToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    try {
      // Make a simple request to test token validity
      final response = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error checking token validity: $e');
      return false;
    }
  }

  // Headers builder with proper Authorization
  Map<String, String> _buildHeaders(String? token) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    } else {
      print('WARNING: Adding headers without token');
    }

    return headers;
  }

  Future<List<Appointment>> getAppointments() async {
    try {
      final token = await _getAuthToken();

      final response = await http.get(
        Uri.parse('$baseUrl/appointments'),
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          final List<dynamic> appointmentsJson = responseData['data'];
          return appointmentsJson
              .map((json) => Appointment.fromJson(json))
              .toList();
        }
      }

      return [];
    } catch (e) {
      print('Error fetching appointments: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> checkAvailability({
    required String date,
    required String time,
    required int duration,
  }) async {
    try {
      final token = await _getAuthToken();

      print(
          'Checking availability: date=$date, time=$time, duration=$duration');

      final response = await http.post(
        Uri.parse('$baseUrl/check-availability'),
        headers: _buildHeaders(token),
        body: jsonEncode({
          'date': date,
          'time': time,
          'duration': duration,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print(
          'Response body (first 100 chars): ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');

      // Check if response is HTML (starts with <!DOCTYPE or <html)
      if (response.body.trim().startsWith('<!DOCTYPE') ||
          response.body.trim().startsWith('<html')) {
        print(
            'Server returned HTML instead of JSON. Possible authentication issue or server error.');
        return {
          'success': false,
          'message':
              'Server returned an unexpected response. Please check your connection and try again.'
        };
      }

      try {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (response.statusCode == 200) {
          return {
            'success': true,
            'available': responseData['available'],
            'date': responseData['date'],
            'startTime': responseData['startTime'],
            'endTime': responseData['endTime'],
            'duration': responseData['duration'],
            'conflictingCount': responseData['conflictingCount'],
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ??
                'Failed to check availability. Please try again.'
          };
        }
      } catch (e) {
        print('Error parsing JSON response: $e');
        return {
          'success': false,
          'message': 'Failed to parse server response. Please try again later.'
        };
      }
    } catch (e) {
      print('Error checking availability: $e');
      return {
        'success': false,
        'message':
            'An error occurred while checking availability: ${e.toString()}'
      };
    }
  }

  Future<Map<String, dynamic>> bookAppointment({
    required String date,
    required String startTime,
    required List<int> serviceIds,
    String? notes,
  }) async {
    try {
      final token = await _getAuthToken();

      // Check if token exists
      if (token == null || token.isEmpty) {
        print('ERROR: Missing authentication token in bookAppointment');
        return {
          'success': false,
          'message': 'Authentication required. Please log in again.'
        };
      }

      // Prepare the request body
      final Map<String, dynamic> requestBody = {
        'services': serviceIds,
        'appointment_date': date,
        'appointment_time': startTime,
        'notes': notes ?? "",
      };

      // Log the exact JSON body being sent
      final String jsonBody = jsonEncode(requestBody);
      print('Booking appointment with JSON body: $jsonBody');
      print(
          'Using token starting with: ${token.length > 10 ? token.substring(0, 10) : token}...');

      final response = await http.post(
        Uri.parse('$baseUrl/appointmentStore'),
        headers: _buildHeaders(token),
        body: jsonBody,
      );

      print('Response status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      // Print the full response body for debugging
      print('Full response body: ${response.body}');

      // Handle authentication errors
      if (response.statusCode == 401 || response.statusCode == 403) {
        print('Authentication error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Authentication failed. Please log in again.'
        };
      }

      // Check if response is HTML (starts with <!DOCTYPE or <html)
      if (response.body.trim().startsWith('<!DOCTYPE') ||
          response.body.trim().startsWith('<html')) {
        print(
            'Server returned HTML instead of JSON. Possible authentication issue or server error.');
        return {
          'success': false,
          'message':
              'Server returned an unexpected response. Please check your connection and try again.'
        };
      }

      try {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (response.statusCode == 201) {
          return {
            'success': true,
            'message': responseData['message'],
            'data': responseData['data']
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to book appointment'
          };
        }
      } catch (e) {
        print('Error parsing JSON response: $e');
        return {
          'success': false,
          'message': 'Failed to parse server response. Please try again later.'
        };
      }
    } catch (e) {
      print('Error booking appointment: $e');
      return {
        'success': false,
        'message': 'An error occurred while booking: ${e.toString()}'
      };
    }
  }

  Future<Map<String, dynamic>> cancelAppointment(int appointmentId) async {
    try {
      final token = await _getAuthToken();

      // Check if token exists
      if (token == null || token.isEmpty) {
        print('ERROR: Missing authentication token in cancelAppointment');
        return {
          'success': false,
          'message': 'Authentication required. Please log in again.'
        };
      }

      print('Cancelling appointment with ID: $appointmentId');

      final String cancelUrl = '$baseUrl/appointments/$appointmentId/cancel';
      print('Cancel URL: $cancelUrl');

      final response = await http.post(
        Uri.parse(cancelUrl),
        headers: _buildHeaders(token),
      );

      print('Cancel response status code: ${response.statusCode}');
      print('Cancel response body: ${response.body}');

      // Handle authentication errors
      if (response.statusCode == 401 || response.statusCode == 403) {
        print('Authentication error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Authentication failed. Please log in again.'
        };
      }

      // Check if response is HTML
      if (response.body.trim().startsWith('<!DOCTYPE') ||
          response.body.trim().startsWith('<html')) {
        print(
            'Server returned HTML instead of JSON. Possible authentication issue or server error.');
        return {
          'success': false,
          'message':
              'Server returned an unexpected response. Please check your connection and try again.'
        };
      }

      try {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (response.statusCode == 200) {
          return {
            'success': true,
            'message':
                responseData['message'] ?? 'Appointment cancelled successfully'
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to cancel appointment'
          };
        }
      } catch (e) {
        print('Error parsing cancel response: $e');
        return {
          'success': false,
          'message': 'Failed to parse server response. Please try again.'
        };
      }
    } catch (e) {
      print('Error cancelling appointment: $e');
      return {
        'success': false,
        'message': 'An error occurred while cancelling: ${e.toString()}'
      };
    }
  }

  Future<Map<String, dynamic>> getBusinessHours() async {
    try {
      final token = await _getAuthToken();

      final response = await http.get(
        Uri.parse('$baseUrl/business-hours'),
        headers: _buildHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);

        return {'success': true, 'data': responseData};
      }

      return {'success': false, 'message': 'Failed to retrieve business hours'};
    } catch (e) {
      print('Error fetching business hours: $e');
      return {
        'success': false,
        'message':
            'An error occurred while fetching business hours: ${e.toString()}'
      };
    }
  }

  // Debug method to test API with hardcoded values
  Future<Map<String, dynamic>> debugTestAppointmentAPI(
      {String? testToken}) async {
    try {
      // If a test token is provided, set it temporarily
      if (testToken != null && testToken.isNotEmpty) {
        setManualToken(testToken);
      }

      final token = await _getAuthToken();

      // Check if token exists
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'error': 'No authentication token available. Please log in again.'
        };
      }

      // Hardcoded example that matches the expected format
      final Map<String, dynamic> requestBody = {
        'services': [1],
        'appointment_date': '2025-06-15',
        'appointment_time': '14:30',
        'notes': 'Test appointment'
      };

      // Log the exact JSON body being sent
      final String jsonBody = jsonEncode(requestBody);
      print('DEBUG - Testing appointment API with JSON body: $jsonBody');
      print('DEBUG - Using token: ${token.substring(0, 10)}...');

      final response = await http.post(
        Uri.parse('$baseUrl/appointmentStore'),
        headers: _buildHeaders(token),
        body: jsonBody,
      );

      print('DEBUG - Response status code: ${response.statusCode}');
      print('DEBUG - Full response body: ${response.body}');

      // Print response headers for debugging
      print('DEBUG - Response headers: ${response.headers}');

      // Return simple result
      return {
        'success': response.statusCode == 201,
        'status_code': response.statusCode,
        'body': response.body
      };
    } catch (e) {
      print('DEBUG - Error testing appointment API: $e');
      return {'success': false, 'error': e.toString()};
    } finally {
      // Clear manual token after test if we set one
      if (testToken != null) {
        _manualToken = null;
      }
    }
  }
}
