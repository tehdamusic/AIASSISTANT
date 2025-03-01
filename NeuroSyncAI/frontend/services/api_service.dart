import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// API Service for handling all network requests to the backend
class ApiService {
  // Base URL of your FastAPI backend
  final String baseUrl;
  
  // Secure storage for auth token
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // HTTP client
  final http.Client _client = http.Client();

  // Constructor
  ApiService({required this.baseUrl});

  // Headers to include in requests
  Future<Map<String, String>> _getHeaders() async {
    final token = await _secureStorage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }

  // GET request
  Future<dynamic> get(String endpoint) async {
    final headers = await _getHeaders();
    final response = await _client.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    
    return _handleResponse(response);
  }

  // POST request
  Future<dynamic> post(String endpoint, {dynamic body}) async {
    final headers = await _getHeaders();
    final response = await _client.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? json.encode(body) : null,
    );
    
    return _handleResponse(response);
  }

  // PUT request
  Future<dynamic> put(String endpoint, {dynamic body}) async {
    final headers = await _getHeaders();
    final response = await _client.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? json.encode(body) : null,
    );
    
    return _handleResponse(response);
  }

  // DELETE request
  Future<dynamic> delete(String endpoint) async {
    final headers = await _getHeaders();
    final response = await _client.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    
    return _handleResponse(response);
  }

  // Handle API responses
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return json.decode(response.body);
      }
      return null;
    } else {
      // Handle errors based on status code
      switch (response.statusCode) {
        case 401:
          throw UnauthorizedException('Unauthorized: ${response.body}');
        case 404:
          throw NotFoundException('Not found: ${response.body}');
        case 500:
          throw ServerException('Server error: ${response.body}');
        default:
          throw ApiException(
            'API Error ${response.statusCode}: ${response.body}',
            response.statusCode,
          );
      }
    }
  }
}

// Custom exceptions for better error handling
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(message, 401);
}

class NotFoundException extends ApiException {
  NotFoundException(String message) : super(message, 404);
}

class ServerException extends ApiException {
  ServerException(String message) : super(message, 500);
}
