import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../models/user.dart';
import '../../utils/logger.dart';
import 'api_client.dart';

class AuthApi {
  final ApiClient _apiClient = ApiClient();
  
  // Endpoint for authentication
  static const String _authEndpoint = '/auth';
  
  // Login with email and password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        '$_authEndpoint/login',
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );
      
      return json.decode(response.body);
    } catch (e) {
      Logger.error('Error during login: $e');
      throw Exception('Failed to login: $e');
    }
  }
  
  // Register a new user
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await _apiClient.post(
        '$_authEndpoint/register',
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );
      
      return json.decode(response.body);
    } catch (e) {
      Logger.error('Error during registration: $e');
      throw Exception('Failed to register: $e');
    }
  }
  
  // Logout
  Future<void> logout() async {
    try {
      await _apiClient.post('$_authEndpoint/logout', body: '{}');
    } catch (e) {
      Logger.error('Error during logout: $e');
      throw Exception('Failed to logout: $e');
    }
  }
  
  // Get user profile
  Future<UserModel> getUserProfile(String userId) async {
    try {
      final response = await _apiClient.get('/users/$userId');
      
      return UserModel.fromJson(json.decode(response.body));
    } catch (e) {
      Logger.error('Error getting user profile: $e');
      throw Exception('Failed to get user profile: $e');
    }
  }
  
  // Update user profile
  Future<UserModel> updateProfile(String userId, Map<String, dynamic> updates) async {
    try {
      final response = await _apiClient.patch(
        '/users/$userId',
        body: json.encode(updates),
      );
      
      return UserModel.fromJson(json.decode(response.body));
    } catch (e) {
      Logger.error('Error updating user profile: $e');
      throw Exception('Failed to update user profile: $e');
    }
  }
  
  // Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      await _apiClient.post(
        '$_authEndpoint/change-password',
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );
    } catch (e) {
      Logger.error('Error changing password: $e');
      throw Exception('Failed to change password: $e');
    }
  }
  
  // Request password reset
  Future<void> requestPasswordReset(String email) async {
    try {
      await _apiClient.post(
        '$_authEndpoint/forgot-password',
        body: json.encode({'email': email}),
      );
    } catch (e) {
      Logger.error('Error requesting password reset: $e');
      throw Exception('Failed to request password reset: $e');
    }
  }
}
