import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Screen imports
import 'screens/tasks/tasks_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/finances/finances_screen.dart';
import 'screens/settings/settings_screen.dart';

// App theme
import 'app/theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: ADHDAssistantApp(),
    ),
  );
}

class ADHDAssistantApp extends ConsumerStatefulWidget {
  const ADHDAssistantApp({Key? key}) : super(key: key);

  @override
  ConsumerState<ADHDAssistantApp> createState() => _ADHDAssistantAppState();
}

class _ADHDAssistantAppState extends ConsumerState<ADHDAssistantApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ADHD Assistant',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

// Navigation
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

// Tab navigation state provider
final currentTabProvider = StateProvider<int>((ref) => 0);

// GoRouter configuration
final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/tasks',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainNavigationScreen(
          location: state.location,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/tasks',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TasksScreen(),
          ),
        ),
        GoRoute(
          path: '/chat',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ChatScreen(),
          ),
        ),
        GoRoute(
          path: '/finances',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: FinancesScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),
  ],
);

class MainNavigationScreen extends ConsumerWidget {
  final String location;
  final Widget child;

  const MainNavigationScreen({
    Key? key,
    required this.location,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the current tab index based on location
    int currentIndex;
    switch (location) {
      case '/tasks':
        currentIndex = 0;
        break;
      case '/chat':
        currentIndex = 1;
        break;
      case '/finances':
        currentIndex = 2;
        break;
      case '/settings':
        currentIndex = 3;
        break;
      default:
        currentIndex = 0;
    }

    // Update the provider state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentTabProvider.notifier).state = currentIndex;
    });

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: (index) {
          // Navigate based on tab index
          switch (index) {
            case 0:
              context.go('/tasks');
              break;
            case 1:
              context.go('/chat');
              break;
            case 2:
              context.go('/finances');
              break;
            case 3:
              context.go('/settings');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Finances',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// Placeholder screens - Replace these with your actual screen imports
class TasksScreen extends StatelessWidget {
  const TasksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Tasks Screen - Checklists & Reminders'),
    );
  }
}

class ChatScreen extends StatelessWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Chat Screen - AI Assistant'),
    );
  }
}

class FinancesScreen extends StatelessWidget {
  const FinancesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Finances Screen - Budget Tracking'),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Settings Screen - User Preferences'),
    );
  }
}
