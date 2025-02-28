import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../services/calendar_service.dart';
import '../widgets/common/loading_indicator.dart';
import 'auth/login_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isCalendarConnecting = false;
  final CalendarService _calendarService = CalendarService();

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: authState.user == null
          ? const Center(child: LoadingIndicator(message: 'Loading user data...'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Profile Section
                  _buildProfileSection(authState.user!),
                  
                  const SizedBox(height: 24.0),
                  
                  // Appearance Settings
                  _buildAppearanceSettings(settingsState),
                  
                  const SizedBox(height: 24.0),
                  
                  // Integrations
                  _buildIntegrationsSection(settingsState),
                  
                  const SizedBox(height: 24.0),
                  
                  // Account Actions
                  _buildAccountActions(),
                ],
              ),
            ),
    );
  }

  // User Profile Section
  Widget _buildProfileSection(UserModel user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16.0),
            
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    // Navigate to profile edit screen
                    // To be implemented
                  },
                  tooltip: 'Edit Profile',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Appearance Settings Section
  Widget _buildAppearanceSettings(SettingsState settingsState) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appearance',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16.0),
            
            // Dark Mode Toggle
            SwitchListTile(
              title: const Text(
                'Dark Mode',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Use dark theme throughout the app',
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.grey[600],
                ),
              ),
              value: settingsState.isDarkMode,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setDarkMode(value);
              },
              secondary: Icon(
                settingsState.isDarkMode
                    ? Icons.dark_mode
                    : Icons.light_mode,
                color: settingsState.isDarkMode
                    ? Colors.amber
                    : Colors.amber[800],
              ),
            ),
            
            const Divider(),
            
            // Text Size Setting
            ListTile(
              title: const Text(
                'Text Size',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Adjust text size throughout the app',
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.grey[600],
                ),
              ),
              leading: const Icon(Icons.text_fields),
              trailing: DropdownButton<String>(
                value: _getTextSizeLabel(settingsState.textSize),
                underline: const SizedBox(),
                items: ['Small', 'Medium', 'Large'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    ref.read(settingsProvider.notifier).setTextSize(
                      _getTextSizeValue(newValue),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Integrations Section
  Widget _buildIntegrationsSection(SettingsState settingsState) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Integrations',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16.0),
            
            // Google Calendar Integration
            ListTile(
              title: const Text(
                'Google Calendar',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                settingsState.isCalendarConnected
                    ? 'Connected - Tap to disconnect'
                    : 'Not connected - Tap to connect',
                style: TextStyle(
                  fontSize: 14.0,
                  color: settingsState.isCalendarConnected
                      ? Colors.green[700]
                      : Colors.grey[600],
                ),
              ),
              leading: Icon(
                Icons.calendar_today,
                color: settingsState.isCalendarConnected
                    ? Colors.green[700]
                    : Colors.grey[600],
              ),
              trailing: _isCalendarConnecting
                  ? const SizedBox(
                      width: 24.0,
                      height: 24.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                      ),
                    )
                  : Icon(
                      settingsState.isCalendarConnected
                          ? Icons.link
                          : Icons.link_off,
                      color: settingsState.isCalendarConnected
                          ? Colors.green[700]
                          : Colors.grey[600],
                    ),
              onTap: _isCalendarConnecting
                  ? null
                  : () => _toggleCalendarConnection(settingsState.isCalendarConnected),
            ),
            
            const Divider(),
            
            // Notification Settings
            ListTile(
              title: const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                settingsState.notificationsEnabled
                    ? 'Enabled'
                    : 'Disabled',
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.grey[600],
                ),
              ),
              leading: const Icon(Icons.notifications_outlined),
              trailing: Switch(
                value: settingsState.notificationsEnabled,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setNotifications(value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Account Actions Section
  Widget _buildAccountActions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16.0),
            
            // Logout Button
            ListTile(
              title: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              onTap: _logout,
            ),
            
            // Clear Data Button
            ListTile(
              title: const Text(
                'Clear App Data',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Reset all app settings and cached data',
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.grey[600],
                ),
              ),
              leading: const Icon(Icons.delete_outline),
              onTap: _showClearDataConfirmation,
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to toggle Google Calendar connection
  Future<void> _toggleCalendarConnection(bool isCurrentlyConnected) async {
    setState(() {
      _isCalendarConnecting = true;
    });

    try {
      if (isCurrentlyConnected) {
        // Disconnect from Google Calendar
        await _calendarService.disconnectCalendar();
        ref.read(settingsProvider.notifier).setCalendarConnected(false);
      } else {
        // Connect to Google Calendar
        final success = await _calendarService.connectCalendar();
        if (success) {
          ref.read(settingsProvider.notifier).setCalendarConnected(true);
        }
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error ${isCurrentlyConnected ? 'disconnecting from' : 'connecting to'} Google Calendar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCalendarConnecting = false;
      });
    }
  }

  // Logout function
  Future<void> _logout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('LOGOUT'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await ref.read(authProvider.notifier).logout();
      
      // Navigate to login screen and clear navigation stack
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  // Show confirmation dialog for clearing data
  Future<void> _showClearDataConfirmation() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear App Data'),
        content: const Text(
          'This will reset all settings and clear cached data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('CLEAR'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      // Clear all app data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // Reset settings provider
      ref.read(settingsProvider.notifier).resetSettings();
      
      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('App data cleared successfully'),
          ),
        );
      }
    }
  }

  // Helper method to get text size label
  String _getTextSizeLabel(double size) {
    if (size <= 0.8) {
      return 'Small';
    } else if (size >= 1.2) {
      return 'Large';
    } else {
      return 'Medium';
    }
  }

  // Helper method to get text size value
  double _getTextSizeValue(String label) {
    switch (label) {
      case 'Small':
        return 0.8;
      case 'Large':
        return 1.2;
      case 'Medium':
      default:
        return 1.0;
    }
  }
}
