# ADHD Assistant App: Finalization & Deployment Guide

## 1. API Connection Testing Guide

### Setting Up Mock Data

#### Create a Mock API Service

```dart
// lib/services/mock_api_service.dart
import 'dart:convert';
import 'dart:async';
import '../models/task.dart';
import '../models/user.dart';

class MockApiService {
  // Mock user data
  static final User mockUser = User(
    id: 1,
    name: 'Test User',
    email: 'test@example.com',
    createdAt: DateTime.now(),
  );
  
  // Mock tasks
  static final List<Map<String, dynamic>> mockTasks = [
    {
      'id': 1,
      'title': 'Complete project proposal',
      'description': 'Draft the initial proposal for client review',
      'due_date': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
      'priority': 'high',
      'is_completed': false,
    },
    {
      'id': 2,
      'title': 'Schedule doctor appointment',
      'description': 'Annual checkup',
      'due_date': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
      'priority': 'medium',
      'is_completed': false,
    },
    {
      'id': 3,
      'title': 'Pay electricity bill',
      'description': 'Due on the 15th',
      'due_date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      'priority': 'high',
      'is_completed': true,
    },
  ];
  
  // Mock financial data
  static final Map<String, dynamic> mockFinancialData = {
    'total_budget': 2500.00,
    'total_spent': 1350.75,
    'remaining': 1149.25,
    'categories': [
      {
        'name': 'Groceries',
        'budget': 500.00,
        'spent': 320.45,
        'color': '#4CAF50'
      },
      {
        'name': 'Utilities',
        'budget': 300.00,
        'spent': 275.30,
        'color': '#2196F3'
      },
      {
        'name': 'Entertainment',
        'budget': 200.00,
        'spent': 150.00,
        'color': '#9C27B0'
      },
      {
        'name': 'Transportation',
        'budget': 150.00,
        'spent': 105.00,
        'color': '#FF9800'
      },
    ]
  };
  
  // Mock calendar events
  static final List<Map<String, dynamic>> mockCalendarEvents = [
    {
      'id': 'evt123',
      'title': 'Team Meeting',
      'start_time': DateTime.now().add(const Duration(hours: 3)).toIso8601String(),
      'end_time': DateTime.now().add(const Duration(hours: 4)).toIso8601String(),
      'location': 'Conference Room A',
    },
    {
      'id': 'evt124',
      'title': 'Dentist Appointment',
      'start_time': DateTime.now().add(const Duration(days: 1, hours: 10)).toIso8601String(),
      'end_time': DateTime.now().add(const Duration(days: 1, hours: 11)).toIso8601String(),
      'location': 'Dental Clinic',
    },
  ];
  
  // Mock login
  Future<Map<String, dynamic>> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
    if (email == 'test@example.com' && password == 'password') {
      return {
        'access_token': 'mock_jwt_token_12345',
        'user_id': 1,
      };
    } else {
      throw Exception('Invalid credentials');
    }
  }
  
  // Mock get tasks
  Future<List<Map<String, dynamic>>> getTasks() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return mockTasks;
  }
  
  // Mock get financial data
  Future<Map<String, dynamic>> getFinancialData() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return mockFinancialData;
  }
  
  // Mock get calendar events
  Future<List<Map<String, dynamic>>> getCalendarEvents() async {
    await Future.delayed(const Duration(milliseconds: 700));
    return mockCalendarEvents;
  }
  
  // Add more mock methods as needed for your app
}
```

#### Creating a Service Switcher

```dart
// lib/services/service_provider.dart
import 'api_service.dart';
import 'mock_api_service.dart';

class ServiceProvider {
  static bool useMock = true; // Toggle between mock and real API
  
  static ApiService getApiService() {
    if (useMock) {
      // Return mock implementation wrapped in real API interface
      return MockApiServiceWrapper(baseUrl: 'mock://api');
    } else {
      return ApiService(baseUrl: 'https://your-real-api.com');
    }
  }
}

// Wrapper to make MockApiService conform to ApiService interface
class MockApiServiceWrapper extends ApiService {
  final MockApiService _mockService = MockApiService();
  
  MockApiServiceWrapper({required String baseUrl}) : super(baseUrl: baseUrl);
  
  @override
  Future<dynamic> get(String endpoint) async {
    if (endpoint.contains('/tasks')) {
      return _mockService.getTasks();
    } else if (endpoint.contains('/finance')) {
      return _mockService.getFinancialData();
    } else if (endpoint.contains('/calendar/events')) {
      return _mockService.getCalendarEvents();
    }
    // Add more endpoint mappings as needed
    
    throw Exception('Mock endpoint not implemented: $endpoint');
  }
  
  @override
  Future<dynamic> post(String endpoint, {dynamic body}) async {
    if (endpoint.contains('/auth/login')) {
      return _mockService.login(body['email'], body['password']);
    }
    // Add more endpoint mappings
    
    throw Exception('Mock endpoint not implemented: $endpoint');
  }
  
  // Implement other methods as needed
}
```

### Testing Different API Scenarios

#### Test Success Scenarios

Create a test screen to verify API connections succeed:

```dart
// lib/screens/api_test_screen.dart
import 'package:flutter/material.dart';
import '../services/service_provider.dart';

class ApiTestScreen extends StatefulWidget {
  @override
  _ApiTestScreenState createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  final _apiService = ServiceProvider.getApiService();
  Map<String, String> _testResults = {};
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('API Connection Tests')),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16),
              children: [
                ElevatedButton(
                  onPressed: _runAllTests,
                  child: Text('Run All API Tests'),
                ),
                SizedBox(height: 16),
                ...buildTestResultWidgets(),
              ],
            ),
    );
  }

  List<Widget> buildTestResultWidgets() {
    return _testResults.entries.map((entry) {
      final bool isSuccess = !entry.value.contains('Error');
      return Card(
        margin: EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(entry.key),
          subtitle: Text(entry.value),
          leading: Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess ? Colors.green : Colors.red,
          ),
        ),
      );
    }).toList();
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isLoading = true;
      _testResults = {};
    });

    // Test login
    await _testApiCall(
      'Login',
      () => _apiService.post('/auth/login', body: {
        'email': 'test@example.com',
        'password': 'password',
      }),
    );

    // Test get tasks
    await _testApiCall(
      'Fetch Tasks',
      () => _apiService.get('/tasks/1'),
    );

    // Test finance data
    await _testApiCall(
      'Fetch Finance Data',
      () => _apiService.get('/finance/summary/1'),
    );

    // Test calendar events
    await _testApiCall(
      'Fetch Calendar Events',
      () => _apiService.get('/calendar/events'),
    );

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testApiCall(String testName, Future<dynamic> Function() apiCall) async {
    try {
      final result = await apiCall();
      setState(() {
        _testResults[testName] = 'Success: ${result != null ? 'Data received' : 'No data'}';
      });
    } catch (e) {
      setState(() {
        _testResults[testName] = 'Error: ${e.toString()}';
      });
    }
  }
}
```

#### Test Failure Scenarios

Modify the mock service to simulate errors:

```dart
// Add this to your MockApiService class
bool _shouldSimulateError = false;

void toggleErrorSimulation(bool shouldSimulateError) {
  _shouldSimulateError = shouldSimulateError;
}

Future<List<Map<String, dynamic>>> getTasks() async {
  await Future.delayed(const Duration(milliseconds: 800));
  
  if (_shouldSimulateError) {
    throw Exception('Network timeout');
  }
  
  return mockTasks;
}
```

Then add error simulation toggle to your test screen:

```dart
Switch(
  value: _simulateErrors,
  onChanged: (value) {
    setState(() {
      _simulateErrors = value;
      // Cast to access the mock service features
      if (_apiService is MockApiServiceWrapper) {
        (_apiService as MockApiServiceWrapper)
            .toggleErrorSimulation(_simulateErrors);
      }
    });
  },
  title: Text('Simulate API Errors'),
)
```

## 2. Performance Optimization Checklist

### 1. UI Rendering Optimization

- [ ] **Use const constructors** where possible for widgets that don't change
  ```dart
  // Before
  return Container(
    padding: EdgeInsets.all(16),
    child: Text('Hello'),
  );
  
  // After
  return const Container(
    padding: EdgeInsets.all(16),
    child: Text('Hello'),
  );
  ```

- [ ] **Implement ListView.builder for long lists** instead of Column with many children
  ```dart
  ListView.builder(
    itemCount: tasks.length,
    itemBuilder: (context, index) => TaskItem(task: tasks[index]),
  )
  ```

- [ ] **Use RepaintBoundary** for complex widgets that don't change often
  ```dart
  RepaintBoundary(
    child: ExpensiveToRenderWidget(),
  )
  ```

- [ ] **Enable profile mode** to identify UI jank and rendering issues
  ```bash
  flutter run --profile
  ```

### 2. Network Optimization

- [ ] **Implement API response caching**
  ```dart
  class CachedApiService {
    final ApiService _apiService;
    final Map<String, dynamic> _cache = {};
    final Map<String, DateTime> _cacheTimestamps = {};
    final Duration _cacheDuration = Duration(minutes: 5);
    
    CachedApiService(this._apiService);
    
    Future<dynamic> get(String endpoint) async {
      final cacheKey = 'GET:$endpoint';
      final cachedData = _cache[cacheKey];
      final cachedTime = _cacheTimestamps[cacheKey];
      
      // Check if cache is valid
      if (cachedData != null && cachedTime != null) {
        final age = DateTime.now().difference(cachedTime);
        if (age < _cacheDuration) {
          return cachedData;
        }
      }
      
      // Fetch fresh data
      final response = await _apiService.get(endpoint);
      
      // Update cache
      _cache[cacheKey] = response;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      return response;
    }
    
    // Implement other methods similarly
    
    void clearCache() {
      _cache.clear();
      _cacheTimestamps.clear();
    }
  }
  ```

- [ ] **Implement request debouncing** for search functions
  ```dart
  Timer? _debounce;
  
  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Execute search
      _performSearch(query);
    });
  }
  ```

- [ ] **Use pagination** for large lists of data
  ```dart
  // In your API service
  Future<List<Task>> getTasks({int page = 1, int pageSize = 20}) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/tasks?page=$page&page_size=$pageSize'),
      headers: await _getHeaders(),
    );
    
    // Parse response
    return _handleResponse(response);
  }
  
  // In your list screen
  int _currentPage = 1;
  final int _pageSize = 20;
  List<Task> _tasks = [];
  bool _isLoading = false;
  bool _hasMoreData = true;
  
  Future<void> _loadMoreTasks() async {
    if (_isLoading || !_hasMoreData) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final newTasks = await _apiService.getTasks(
        page: _currentPage,
        pageSize: _pageSize,
      );
      
      setState(() {
        _tasks.addAll(newTasks);
        _currentPage++;
        _hasMoreData = newTasks.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  ```

- [ ] **Use a connection-aware service** to handle online/offline states
  ```dart
  import 'package:connectivity_plus/connectivity_plus.dart';
  
  class NetworkAwareApiService {
    final ApiService _apiService;
    final Connectivity _connectivity = Connectivity();
    
    NetworkAwareApiService(this._apiService);
    
    Future<bool> _isConnected() async {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    }
    
    Future<dynamic> get(String endpoint) async {
      if (!await _isConnected()) {
        // Handle offline state, e.g. return cached data
        throw OfflineException('No internet connection');
      }
      
      return _apiService.get(endpoint);
    }
    
    // Implement other methods similarly
  }
  
  class OfflineException implements Exception {
    final String message;
    OfflineException(this.message);
    @override
    String toString() => message;
  }
  ```

### 3. Memory Management

- [ ] **Dispose controllers** in State objects
  ```dart
  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  ```

- [ ] **Cancel timers and subscriptions**
  ```dart
  StreamSubscription? _subscription;
  Timer? _refreshTimer;
  
  @override
  void dispose() {
    _subscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }
  ```

- [ ] **Optimize image loading** with cached_network_image
  ```dart
  CachedNetworkImage(
    imageUrl: task.imageUrl,
    placeholder: (context, url) => CircularProgressIndicator(),
    errorWidget: (context, url, error) => Icon(Icons.error),
  )
  ```

- [ ] **Lazy load offscreen content** with tabs
  ```dart
  DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: AppBar(
        bottom: TabBar(
          tabs: [
            Tab(icon: Icon(Icons.task), text: 'Tasks'),
            Tab(icon: Icon(Icons.chat), text: 'AI Chat'),
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Finance'),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          TasksScreen(),
          ChatScreen(),
          FinanceScreen(),
        ],
      ),
    ),
  )
  ```

- [ ] **Use lazy singletons** for services to avoid multiple instances
  ```dart
  class ServiceLocator {
    static final ServiceLocator _instance = ServiceLocator._internal();
    factory ServiceLocator() => _instance;
    ServiceLocator._internal();
    
    ApiService? _apiService;
    
    ApiService get apiService {
      _apiService ??= ApiService(baseUrl: 'https://your-api.com');
      return _apiService!;
    }
    
    // Other services
  }
  ```

### 4. State Management Optimization

- [ ] **Use context-free state management** where appropriate (Provider, Riverpod, Bloc)
  ```dart
  // Using Provider pattern for better performance
  final taskProvider = StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
    return TaskNotifier();
  });
  
  class TaskNotifier extends StateNotifier<List<Task>> {
    final ApiService _apiService = ApiService(baseUrl: 'https://your-api.com');
    
    TaskNotifier() : super([]) {
      loadTasks();
    }
    
    Future<void> loadTasks() async {
      try {
        final tasks = await _apiService.getTasks();
        state = tasks;
      } catch (e) {
        // Handle error
      }
    }
    
    // Other methods
  }
  ```

- [ ] **Minimize widget rebuilds** with selective state updates
  ```dart
  // Before
  setState(() {
    _allData = newData;  // Rebuilds entire widget tree
  });
  
  // After - selective update
  setState(() {
    _tasks = newData.tasks;  // Only update what changed
  });
  ```

## 3. Flutter Network Debugging Tips

### Common Network Errors and Solutions

#### 1. Certificate Verification Errors

**Error:** `HandshakeException: Handshake error in client (OS Error: CERTIFICATE_VERIFY_FAILED)`

**Solution:**
- For development, add this to your `main.dart` (remove before production):
  ```dart
  import 'dart:io';
  
  void main() {
    // For development only!
    HttpOverrides.global = DevHttpOverrides();
    runApp(MyApp());
  }
  
  class DevHttpOverrides extends HttpOverrides {
    @override
    HttpClient createHttpClient(SecurityContext? context) {
      return super.createHttpClient(context)
        ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    }
  }
  ```

- For production, ensure your SSL certificates are valid

#### 2. Connection Timeouts

**Error:** `SocketException: Connection timed out`

**Solution:**
- Implement timeout handling in your ApiService:
  ```dart
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl$endpoint'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));
      
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Request timed out', 408);
    }
  }
  ```

- Create a retry mechanism:
  ```dart
  Future<dynamic> getWithRetry(String endpoint, {int maxRetries = 3}) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await get(endpoint);
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) rethrow;
        await Future.delayed(Duration(seconds: 1 * attempts));
      }
    }
  }
  ```

#### 3. Parsing Errors

**Error:** `FormatException: Unexpected character` or `type 'Null' is not a subtype of type 'String'`

**Solution:**
- Implement robust JSON parsing:
  ```dart
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dueDate: json['due_date'] != null 
          ? DateTime.tryParse(json['due_date']) 
          : null,
      priority: json['priority'] ?? 'medium',
      isCompleted: json['is_completed'] ?? false,
    );
  }
  ```

- Use a try-catch for parsing:
  ```dart
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        try {
          return json.decode(response.body);
        } catch (e) {
          throw ApiException('Failed to parse response: ${e.toString()}', response.statusCode);
        }
      }
      return null;
    } else {
      // Error handling
    }
  }
  ```

#### 4. Auth Token Expiry

**Error:** `ApiException: Unauthorized: Token expired`

**Solution:**
- Implement token refresh logic:
  ```dart
  Future<dynamic> _executeWithTokenRefresh(Future<dynamic> Function() apiCall) async {
    try {
      return await apiCall();
    } on UnauthorizedException catch (e) {
      if (e.message.contains('expired')) {
        // Try to refresh token
        await _refreshToken();
        // Retry the call
        return await apiCall();
      } else {
        rethrow;
      }
    }
  }
  
  Future<void> _refreshToken() async {
    final refreshToken = await _secureStorage.read(key: 'refresh_token');
    if (refreshToken == null) throw UnauthorizedException('No refresh token available');
    
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'refresh_token': refreshToken}),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await _secureStorage.write(key: 'auth_token', value: data['access_token']);
    } else {
      // Failed to refresh, require re-login
      throw UnauthorizedException('Session expired. Please log in again.');
    }
  }
  ```

### Debugging Tools and Techniques

#### Network Logging with Dio

Replace http with dio and use its logging interceptor:

```dart
import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio;
  
  ApiService({required String baseUrl}) :
    _dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    // Add logging interceptor
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }
  
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await _dio.get(endpoint);
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }
  
  void _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        throw ApiException('Connection timeout', 408);
      case DioExceptionType.receiveTimeout:
        throw ApiException('Receive timeout', 408);
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 500;
        final message = e.response?.data?['message'] ?? 'Unknown error';
        if (statusCode == 401) {
          throw UnauthorizedException('Unauthorized: $message');
        } else if (statusCode == 404) {
          throw NotFoundException('Not found: $message');
        } else {
          throw ApiException('Error $statusCode: $message', statusCode);
        }
      default:
        throw ApiException('Network error: ${e.message}', 500);
    }
  }
}
```

#### Using Flutter DevTools for Network Inspection

1. Run your app with DevTools:
   ```bash
   flutter run
   ```

2. Open DevTools in your browser when prompted or by running:
   ```bash
   flutter devtools
   ```

3. Use the Network tab to inspect requests and responses

#### Create a Network Monitor Widget

Add this debug widget to overlay network activity:

```dart
class NetworkMonitorOverlay extends StatefulWidget {
  final Widget child;
  
  const NetworkMonitorOverlay({Key? key, required this.child}) : super(key: key);
  
  @override
  _NetworkMonitorOverlayState createState() => _NetworkMonitorOverlayState();
}

class _NetworkMonitorOverlayState extends State<NetworkMonitorOverlay> {
  int _activeRequests = 0;
  List<String> _recentRequests = [];
  bool _expanded = false;
  
  void addRequest(String url) {
    setState(() {
      _activeRequests++;
      _recentRequests.add('${DateTime.now().toString().substring(11, 19)} - $url');
      if (_recentRequests.length > 5) _recentRequests.removeAt(0);
    });
  }
  
  void completeRequest() {
    setState(() {
      _activeRequests = (_activeRequests - 1).clamp(0, double.infinity).toInt();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: EdgeInsets.all(8),
              color: Colors.black54,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_activeRequests > 0) 
                        SizedBox(
                          height: 12,
                          width: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      SizedBox(width: 4),
                      Text(
                        'Network: $_activeRequests active',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                  if (_expanded)
                    ...List.generate(_recentRequests.length, (index) {
                      return Text(
                        _recentRequests[index],
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      );
                    }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

Use a custom HTTP client that reports to the monitor:

```dart
// Create a global key for the monitor
final networkMonitorKey = GlobalKey<_NetworkMonitorOverlayState>();

// In main.dart
MaterialApp(
  home: NetworkMonitorOverlay(
    key: networkMonitorKey,
    child: HomeScreen(),
  ),
)

// Custom HTTP client
class MonitoredHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Notify monitor of new request
    networkMonitorKey.currentState?.addRequest(request.url.toString());
    
    try {
      final response = await _inner.send(request);
      // Notify monitor of completion
      networkMonitorKey.currentState?.completeRequest();
      return response;
    } catch (e) {
      // Notify monitor of completion (even with error)
      networkMonitorKey.currentState?.completeRequest();
      rethrow;
    }
  }
}
```

## Final Pre-Deployment Checklist

- [ ] **Run Flutter analyze** to catch code issues
  ```bash
  flutter analyze
  ```

- [ ] **Run Flutter tests**
  ```bash
  flutter test
  ```

- [ ] **Check for memory leaks** with Flutter DevTools

- [ ] **Test on multiple device sizes** and orientations

- [ ] **Enable error reporting** with a service like Firebase Crashlytics

- [ ] **Implement app versioning** for update tracking
  ```dart
  // In main.dart
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  String version = packageInfo.version;
  String buildNumber = packageInfo.buildNumber;
  ```

- [ ] **Add offline support** for critical features

- [ ] **Verify all Firebase/backend configurations** are set for production

- [ ] **Test the app on slow networks** by throttling connection

- [ ] **Run performance profiling** in release mode
  ```bash
  flutter run --profile --trace-skia
  ```

- [ ] **Review app permissions** and minimize them

- [ ] **Test with different users** and roles

- [ ] **Verify deep linking** works as expected

- [ ] **Check for console errors** in debug console

- [ ] **Test logout and login flow** with token expiry

- [ ] **Verify background/foreground transitions** handle state correctly

- [ ] **Build a release version** and test thoroughly
  ```bash
  flutter build apk --release
  flutter build ios --release
  ```
