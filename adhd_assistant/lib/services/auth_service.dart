import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthService(this._apiService);

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      if (token == null) return false;
      
      // Verify token with backend
      await _apiService.get('/auth/verify');
      return true;
    } catch (e) {
      // Token invalid or verification failed
      await logout();
      return false;
    }
  }

  // Get current user ID
  Future<String?> getUserId() async {
    return await _secureStorage.read(key: 'user_id');
  }

  // Login user
  Future<void> login(String email, String password) async {
    final response = await _apiService.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    
    // Store auth token and user ID
    await _secureStorage.write(key: 'auth_token', value: response['access_token']);
    await _secureStorage.write(key: 'user_id', value: response['user_id'].toString());
  }

  // Register new user
  Future<void> register(String name, String email, String password) async {
    final response = await _apiService.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
    });
    
    // Store auth token and user ID
    await _secureStorage.write(key: 'auth_token', value: response['access_token']);
    await _secureStorage.write(key: 'user_id', value: response['user_id'].toString());
  }

  // Logout user
  Future<void> logout() async {
    // Clear stored data
    await _secureStorage.delete(key: 'auth_token');
    await _secureStorage.delete(key: 'user_id');
    
    // You can also make a backend call to invalidate the token
    try {
      await _apiService.post('/auth/logout');
    } catch (e) {
      // If the logout API call fails, still proceed with local logout
    }
  }
}
