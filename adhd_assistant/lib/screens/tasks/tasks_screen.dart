import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../widgets/tasks/task_list_item.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_view.dart';
import 'task_creation_screen.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch tasks when screen is initialized
    Future.microtask(() => ref.read(taskProvider.notifier).fetchTasks());
  }

  @override
  Widget build(BuildContext context) {
    // Watch the task state
    final taskState = ref.watch(taskProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Tasks',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterOptions(context);
            },
            tooltip: 'Filter Tasks',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(taskProvider.notifier).fetchTasks();
            },
            tooltip: 'Refresh Tasks',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(taskState),
            
            // Main task list
            Expanded(
              child: _buildTaskList(taskState),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateTask(context),
        label: const Text('Add Task'),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        tooltip: 'Add a new task',
      ),
    );
  }

  Widget _buildProgressIndicator(TaskState taskState) {
    // Calculate completion percentage
    final completedTasks = taskState.tasks
        .where((task) => task.isCompleted)
        .length;
    final totalTasks = taskState.tasks.length;
    final completionPercentage = totalTasks > 0 
        ? (completedTasks / totalTasks) 
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              Text(
                '${(completionPercentage * 100).toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: completionPercentage,
            minHeight: 12,
            backgroundColor: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 16),
          const Divider(thickness: 1),
        ],
      ),
    );
  }

  Widget _buildTaskList(TaskState taskState) {
    // Display different views based on the task state
    if (taskState.isLoading) {
      return const LoadingIndicator(message: 'Loading your tasks...');
    }
    
    if (taskState.error != null) {
      return ErrorView(
        message: 'Error loading tasks: ${taskState.error}',
        onRetry: () => ref.read(taskProvider.notifier).fetchTasks(),
      );
    }
    
    if (taskState.tasks.isEmpty) {
      return _buildEmptyState();
    }
    
    // Return actual task list
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: taskState.tasks.length,
      itemBuilder: (context, index) {
        final task = taskState.tasks[index];
        return TaskListItem(
          task: task,
          onToggle: (isCompleted) {
            ref.read(taskProvider.notifier).toggleTaskCompletion(task.id, isCompleted);
          },
          onDelete: () {
            _showDeleteConfirmation(context, task);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first task',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateTask(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TaskCreationScreen(),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              ref.read(taskProvider.notifier).deleteTask(task.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('DELETE'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Tasks',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('All Tasks'),
              onTap: () {
                ref.read(taskProvider.notifier).filterTasks(TaskFilter.all);
                Navigator.of(ctx).pop();
              },
              tileColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Completed Tasks'),
              onTap: () {
                ref.read(taskProvider.notifier).filterTasks(TaskFilter.completed);
                Navigator.of(ctx).pop();
              },
              tileColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.circle_outlined),
              title: const Text('Incomplete Tasks'),
              onTap: () {
                ref.read(taskProvider.notifier).filterTasks(TaskFilter.incomplete);
                Navigator.of(ctx).pop();
              },
              tileColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
