import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Settings state class
class SettingsState {
  final bool isDarkMode;
  final double textSize;
  final bool isCalendarConnected;
  final bool notificationsEnabled;

  SettingsState({
    required this.isDarkMode,
    required this.textSize,
    required this.isCalendarConnected,
    required this.notificationsEnabled,
  });

  // Create initial state
  factory SettingsState.initial() {
    return SettingsState(
      isDarkMode: false,
      textSize: 1.0,
      isCalendarConnected: false,
      notificationsEnabled: true,
    );
  }

  // Create a copy with updated fields
  SettingsState copyWith({
    bool? isDarkMode,
    double? textSize,
    bool? isCalendarConnected,
    bool? notificationsEnabled,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      textSize: textSize ?? this.textSize,
      isCalendarConnected: isCalendarConnected ?? this.isCalendarConnected,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

// Settings notifier for state updates
class SettingsNotifier extends StateNotifier<SettingsState> {
  static const String _darkModeKey = 'dark_mode';
  static const String _textSizeKey = 'text_size';
  static const String _calendarConnectedKey = 'calendar_connected';
  static const String _notificationsEnabledKey = 'notifications_enabled';

  SettingsNotifier() : super(SettingsState.initial()) {
    _loadSettings();
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final isDarkMode = prefs.getBool(_darkModeKey) ?? false;
    final textSize = prefs.getDouble(_textSizeKey) ?? 1.0;
    final isCalendarConnected = prefs.getBool(_calendarConnectedKey) ?? false;
    final notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
    
    state = SettingsState(
      isDarkMode: isDarkMode,
      textSize: textSize,
      isCalendarConnected: isCalendarConnected,
      notificationsEnabled: notificationsEnabled,
    );
  }

  // Set dark mode
  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
    state = state.copyWith(isDarkMode: value);
  }

  // Set text size
  Future<void> setTextSize(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textSizeKey, value);
    state = state.copyWith(textSize: value);
  }

  // Set calendar connected
  Future<void> setCalendarConnected(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_calendarConnectedKey, value);
    state = state.copyWith(isCalendarConnected: value);
  }

  // Set notifications enabled
  Future<void> setNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, value);
    state = state.copyWith(notificationsEnabled: value);
  }

  // Reset settings to default
  Future<void> resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_darkModeKey);
    await prefs.remove(_textSizeKey);
    await prefs.remove(_calendarConnectedKey);
    await prefs.remove(_notificationsEnabledKey);
    
    state = SettingsState.initial();
  }
}

// Settings provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
