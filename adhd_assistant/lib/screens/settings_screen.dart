import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _apiService = ApiService(baseUrl: 'YOUR_API_BASE_URL');
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final AuthService _authService;
  
  bool _isLoading = false;
  bool _isCalendarConnected = false;
  bool _autoSyncEnabled = false;
  bool _reminderNotificationsEnabled = true;
  String _userName = '';
  String _userEmail = '';

  _SettingsScreenState() : _authService = AuthService(ApiService(baseUrl: 'YOUR_API_BASE_URL'));

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkCalendarAuthStatus();
  }

  // Load user profile data
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = await _secureStorage.read(key: 'user_id');
      if (userId != null) {
        final userData = await _apiService.get('/users/$userId');
        setState(() {
          _userName = userData['name'] ?? '';
          _userEmail = userData['email'] ?? '';
        });
      }
      
      // Load calendar sync preferences
      final autoSync = await _secureStorage.read(key: 'calendar_auto_sync');
      final reminders = await _secureStorage.read(key: 'reminder_notifications');
      
      setState(() {
        _autoSyncEnabled = autoSync == 'true';
        _reminderNotificationsEnabled = reminders != 'false'; // Default to true
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load settings: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Check Google Calendar authentication status
  Future<void> _checkCalendarAuthStatus() async {
    try {
      final token = await _secureStorage.read(key: 'google_calendar_token');
      setState(() {
        _isCalendarConnected = token != null;
      });
    } catch (e) {
      // Silently fail
    }
  }

  // Connect to Google Calendar
  Future<void> _connectGoogleCalendar() async {
    setState(() => _isLoading = true);
    
    try {
      // Get auth URL from backend
      final response = await _apiService.get('/calendar/authenticate');
      final authUrl = response['auth_url'];
      
      // Open auth URL in WebView or browser
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => _GoogleAuthWebView(
            authUrl: authUrl,
            apiService: _apiService,
          ),
        ),
      );
      
      if (result == true) {
        setState(() {
          _isCalendarConnected = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Calendar connected successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect Google Calendar: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Disconnect Google Calendar
  Future<void> _disconnectGoogleCalendar() async {
    setState(() => _isLoading = true);
    
    try {
      await _apiService.post('/calendar/disconnect');
      await _secureStorage.delete(key: 'google_calendar_token');
      
      setState(() {
        _isCalendarConnected = false;
        _autoSyncEnabled = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Calendar disconnected')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to disconnect: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Toggle auto sync
  Future<void> _toggleAutoSync(bool value) async {
    if (!_isCalendarConnected && value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect Google Calendar first')),
      );
      return;
    }
    
    setState(() => _autoSyncEnabled = value);
    await _secureStorage.write(key: 'calendar_auto_sync', value: value.toString());
    
    // Update backend preference
    try {
      await _apiService.post('/calendar/preferences', body: {
        'auto_sync': value,
      });
    } catch (e) {
      // Revert on failure
      setState(() => _autoSyncEnabled = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update sync preference: ${e.toString()}')),
      );
    }
  }

  // Toggle reminder notifications
  Future<void> _toggleReminderNotifications(bool value) async {
    setState(() => _reminderNotificationsEnabled = value);
    await _secureStorage.write(key: 'reminder_notifications', value: value.toString());
    
    // Update backend preference
    try {
      await _apiService.post('/notifications/preferences', body: {
        'task_reminders': value,
      });
    } catch (e) {
      // Silently fail but keep the local preference
    }
  }

  // Logout user
  Future<void> _logout() async {
    setState(() => _isLoading = true);
    
    try {
      await _authService.logout();
      
      // Navigate to login screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User profile section
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Account',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                child: Text(
                                  _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                              title: Text(_userName),
                              subtitle: Text(_userEmail),
                              contentPadding: EdgeInsets.zero,
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _logout,
                              icon: const Icon(Icons.logout),
                              label: const Text('Logout'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Calendar integration section
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Google Calendar Integration',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Connection status
                            Row(
                              children: [
                                Icon(
                                  _isCalendarConnected
                                      ? Icons.check_circle
                                      : Icons.error_outline,
                                  color: _isCalendarConnected
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isCalendarConnected
                                      ? 'Connected'
                                      : 'Not connected',
                                  style: TextStyle(
                                    color: _isCalendarConnected
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                                const Spacer(),
                                _isCalendarConnected
                                    ? OutlinedButton(
                                        onPressed: _disconnectGoogleCalendar,
                                        child: const Text('Disconnect'),
                                      )
                                    : ElevatedButton.icon(
                                        onPressed: _connectGoogleCalendar,
                                        icon: SvgPicture.asset(
                                          'assets/icons/google_logo.svg',
                                          height: 20,
                                          width: 20,
                                        ),
                                        label: const Text('Connect'),
                                      ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Auto sync toggle
                            SwitchListTile(
                              title: const Text('Auto-sync Calendar Events'),
                              subtitle: const Text(
                                'Automatically import Google Calendar events as tasks',
                              ),
                              value: _autoSyncEnabled,
                              onChanged: _isCalendarConnected
                                  ? _toggleAutoSync
                                  : null,
                              activeColor: Theme.of(context).colorScheme.primary,
                              contentPadding: EdgeInsets.zero,
                            ),
                            
                            if (_isCalendarConnected) ...[
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  try {
                                    await _apiService.post('/calendar/sync-now');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Calendar synced successfully!'),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Sync failed: ${e.toString()}'),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.sync),
                                label: const Text('Sync Now'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    
                    // Notifications section
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Reminder notifications toggle
                            SwitchListTile(
                              title: const Text('Task Reminders'),
                              subtitle: const Text(
                                'Receive notifications for upcoming tasks',
                              ),
                              value: _reminderNotificationsEnabled,
                              onChanged: _toggleReminderNotifications,
                              activeColor: Theme.of(context).colorScheme.primary,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // App info section
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'About',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              title: const Text('Version'),
                              subtitle: const Text('1.0.0'),
                              contentPadding: EdgeInsets.zero,
                            ),
                            const Divider(),
                            ListTile(
                              title: const Text('Terms of Service'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              contentPadding: EdgeInsets.zero,
                              onTap: () {
                                // Navigate to terms of service
                              },
                            ),
                            const Divider(),
                            ListTile(
                              title: const Text('Privacy Policy'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              contentPadding: EdgeInsets.zero,
                              onTap: () {
                                // Navigate to privacy policy
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// Google Auth WebView
class _GoogleAuthWebView extends StatefulWidget {
  final String authUrl;
  final ApiService apiService;

  const _GoogleAuthWebView({
    Key? key,
    required this.authUrl,
    required this.apiService,
  }) : super(key: key);

  @override
  _GoogleAuthWebViewState createState() => _GoogleAuthWebViewState();
}

class _GoogleAuthWebViewState extends State<_GoogleAuthWebView> {
  late WebViewController _controller;
  bool _isLoading = true;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Check if the URL contains the redirect URI with an auth code
            if (request.url.contains('code=')) {
              _handleAuthCode(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authUrl));
  }

  // Extract auth code and complete OAuth flow
  Future<void> _handleAuthCode(String url) async {
    final uri = Uri.parse(url);
    final code = uri.queryParameters['code'];
    
    if (code != null) {
      try {
        // Exchange code for token
        final response = await widget.apiService.post('/calendar/complete-auth', body: {
          'code': code,
        });
        
        // Store token
        await _secureStorage.write(
          key: 'google_calendar_token',
          value: response['access_token'],
        );
        
        // Return success and close WebView
        Navigator.of(context).pop(true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication failed: ${e.toString()}')),
        );
        Navigator.of(context).pop(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Google Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
