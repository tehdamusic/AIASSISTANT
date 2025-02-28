import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../services/api/auth_api.dart';
import '../services/local/shared_prefs_service.dart';
import '../services/local/secure_storage_service.dart';

// Auth state class
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  // Create initial state
  factory AuthState.initial() {
    return AuthState(
      user: null,
      isLoading: true, // Start with loading state to check for existing session
      error: null,
      isAuthenticated: false,
    );
  }

  // Create loading state
  AuthState copyWithLoading() {
    return AuthState(
      user: this.user,
      isLoading: true,
      error: null,
      isAuthenticated: this.isAuthenticated,
    );
  }

  // Create error state
  AuthState copyWithError(String errorMessage) {
    return AuthState(
      user: this.user,
      isLoading: false,
      error: errorMessage,
      isAuthenticated: this.isAuthenticated,
    );
  }

  // Create authenticated state
  AuthState copyWithUser(UserModel user) {
    return AuthState(
      user: user,
      isLoading: false,
      error: null,
      isAuthenticated: true,
    );
  }

  // Create unauthenticated state
  AuthState copyWithLogout() {
    return AuthState(
      user: null,
      isLoading: false,
      error: null,
      isAuthenticated: false,
    );
  }
}

// Auth notifier for state updates
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApi _authApi;
  final SharedPrefsService _prefs;
  final SecureStorageService _secureStorage;

  AuthNotifier(this._authApi, this._prefs, this._secureStorage) 
      : super(AuthState.initial()) {
    // Check for existing session on initialization
    checkAuthStatus();
  }

  // Check if user is already logged in
  Future<void> checkAuthStatus() async {
    try {
      final token = await _secureStorage.getAuthToken();
      if (token == null) {
        state = state.copyWithLogout();
        return;
      }

      final userId = await _prefs.getUserId();
      if (userId == null) {
        state = state.copyWithLogout();
        return;
      }

      // Get user data
      final user = await _authApi.getUserProfile(userId);
      state = state.copyWithUser(user);
    } catch (e) {
      // If there's an error, clear tokens and set unauthenticated state
      await _secureStorage.clearAuthToken();
      await _prefs.clearUserData();
      state = state.copyWithLogout();
    }
  }

  // Login with email and password
  Future<void> login(String email, String password) async {
    state = state.copyWithLoading();

    try {
      final response = await _authApi.login(email, password);
      
      // Save auth token securely
      await _secureStorage.setAuthToken(response['token']);
      
      // Save user ID
      await _prefs.setUserId(response['userId']);
      
      // Get user data
      final user = await _authApi.getUserProfile(response['userId']);
      state = state.copyWithUser(user);
    } catch (e) {
      state = state.copyWithError(e.toString());
    }
  }

  // Register new user
  Future<void> register(String name, String email, String password) async {
    state = state.copyWithLoading();

    try {
      final response = await _authApi.register(name, email, password);
      
      // Save auth token securely
      await _secureStorage.setAuthToken(response['token']);
      
      // Save user ID
      await _prefs.setUserId(response['userId']);
      
      // Get user data
      final user = await _authApi.getUserProfile(response['userId']);
      state = state.copyWithUser(user);
    } catch (e) {
      state = state.copyWithError(e.toString());
    }
  }

  // Logout
  Future<void> logout() async {
    state = state.copyWithLoading();

    try {
      // Call logout API
      await _authApi.logout();
      
      // Clear tokens and user data
      await _secureStorage.clearAuthToken();
      await _prefs.clearUserData();
      
      state = state.copyWithLogout();
    } catch (e) {
      // Even if API fails, still clear local data
      await _secureStorage.clearAuthToken();
      await _prefs.clearUserData();
      state = state.copyWithLogout();
    }
  }

  // Update user profile
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (state.user == null) {
      state = state.copyWithError('No authenticated user');
      return;
    }

    state = state.copyWithLoading();

    try {
      final updatedUser = await _authApi.updateProfile(state.user!.id, updates);
      state = state.copyWithUser(updatedUser);
    } catch (e) {
      state = state.copyWithError(e.toString());
    }
  }
}

// Auth API provider
final authApiProvider = Provider<AuthApi>((ref) => AuthApi());

// Secure storage provider
final secureStorageProvider = Provider<SecureStorageService>((ref) => SecureStorageService());

// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authApi = ref.watch(authApiProvider);
  final prefs = ref.watch(sharedPrefsProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthNotifier(authApi, prefs, secureStorage);
});

// Shared prefs provider (if not already defined elsewhere)
final sharedPrefsProvider = Provider<SharedPrefsService>((ref) => SharedPrefsService());
