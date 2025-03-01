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

  void _completeTask(Task task) async {
    await ref.read(taskProvider.notifier).completeTask(task.id);

    if (task.isRecurring) {
      // Refresh tasks only if the completed task was recurring
      ref.read(taskProvider.notifier).fetchTasks();
    }
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
        onPressed: () => _navigateToTaskCreation(context),
        label: const Text("New Task"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskList(TaskState taskState) {
    if (taskState.isLoading) {
      return const LoadingIndicator();
    }

    if (taskState.errorMessage != null) {
      return ErrorView(
        message: taskState.errorMessage!,
        onRetry: () => ref.read(taskProvider.notifier).fetchTasks(),
      );
    }

    return ListView.builder(
      itemCount: taskState.tasks.length,
      itemBuilder: (context, index) {
        final task = taskState.tasks[index];
        return TaskListItem(
          task: task,
          onComplete: () => _completeTask(task),
        );
      },
    );
  }
}
