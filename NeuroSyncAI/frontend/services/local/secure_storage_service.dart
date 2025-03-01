import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Keys
  static const String _authTokenKey = 'auth_token';
  
  // Get auth token
  Future<String?> getAuthToken() async {
    return await _storage.read(key: _authTokenKey);
  }
  
  // Set auth token
  Future<void> setAuthToken(String token) async {
    await _storage.write(key: _authTokenKey, value: token);
  }
  
  // Clear auth token
  Future<void> clearAuthToken() async {
    await _storage.delete(key: _authTokenKey);
  }
  
  // Clear all secure storage
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
