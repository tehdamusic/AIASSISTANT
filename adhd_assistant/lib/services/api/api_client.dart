import 'dart:convert';
import 'package:http/http.dart' as http;

import '../local/shared_prefs_service.dart';

class ApiClient {
  final String baseUrl = 'https://your-fastapi-backend.com/api'; // Replace with your actual API URL
  final SharedPrefsService _prefs = SharedPrefsService();
  
  // Get request
  Future<http.Response> get(String endpoint) async {
    final token = await _prefs.getAuthToken();
    
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    _validateResponse(response);
    return response;
  }
  
  // Post request
  Future<http.Response> post(String endpoint, {required String body}) async {
    final token = await _prefs.getAuthToken();
    
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );
    
    _validateResponse(response);
    return response;
  }
  
  // Patch request
  Future<http.Response> patch(String endpoint, {required String body}) async {
    final token = await _prefs.getAuthToken();
    
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );
    
    _validateResponse(response);
    return response;
  }
  
  // Delete request
  Future<http.Response> delete(String endpoint) async {
    final token = await _prefs.getAuthToken();
    
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    _validateResponse(response);
    return response;
  }
  
  // Validate response
  void _validateResponse(http.Response response) {
    if (response.statusCode >= 400) {
      Map<String, dynamic> body = {};
      
      try {
        body = json.decode(response.body);
      } catch (e) {
        // If JSON parsing fails, use the status code
        throw Exception('Request failed with status: ${response.statusCode}');
      }
      
      final message = body['detail'] ?? body['message'] ?? 'Unknown error';
      throw Exception(message);
    }
  }
}
