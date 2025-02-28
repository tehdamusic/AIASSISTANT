import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class CalendarService {
  final ApiService _apiService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  CalendarService(this._apiService);

  // Check if calendar is connected
  Future<bool> isCalendarConnected() async {
    try {
      final token = await _secureStorage.read(key: 'google_calendar_token');
      return token != null;
    } catch (e) {
      return false;
    }
  }

  // Get auto-sync preference
  Future<bool> getAutoSyncPreference() async {
    try {
      final autoSync = await _secureStorage.read(key: 'calendar_auto_sync');
      return autoSync == 'true';
    } catch (e) {
      return false;
    }
  }

  // Sync calendar events now
  Future<void> syncCalendarEvents() async {
    await _apiService.post('/calendar/sync-now');
  }

  // Get authentication URL for Google Calendar
  Future<String> getAuthUrl() async {
    final response = await _apiService.get('/calendar/authenticate');
    return response['auth_url'];
  }

  // Complete OAuth flow with auth code
  Future<void> completeAuthentication(String code) async {
    final response = await _apiService.post('/calendar/complete-auth', body: {
      'code': code,
    });
    
    await _secureStorage.write(
      key: 'google_calendar_token',
      value: response['access_token'],
    );
  }

  // Disconnect Google Calendar
  Future<void> disconnectCalendar() async {
    await _apiService.post('/calendar/disconnect');
    await _secureStorage.delete(key: 'google_calendar_token');
  }

  // Update calendar preferences
  Future<void> updatePreferences({required bool autoSync}) async {
    await _apiService.post('/calendar/preferences', body: {
      'auto_sync': autoSync,
    });
    
    await _secureStorage.write(
      key: 'calendar_auto_sync',
      value: autoSync.toString(),
    );
  }

  // Get synced calendar events
  Future<List<Map<String, dynamic>>> getSyncedEvents() async {
    final response = await _apiService.get('/calendar/events');
    return List<Map<String, dynamic>>.from(response['events']);
  }
}
