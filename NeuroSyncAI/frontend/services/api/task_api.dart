import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../models/task.dart';
import '../../utils/logger.dart';
import '../local/shared_prefs_service.dart';
import 'api_client.dart';

class TaskApi {
  final ApiClient _apiClient = ApiClient();
  final SharedPrefsService _prefs = SharedPrefsService();
  
  // Endpoint for tasks
  static const String _tasksEndpoint = '/tasks';
  
  // Get all tasks for the current user
  Future<List<Task>> getTasks() async {
    try {
      final userId = await _prefs.getUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }
      
      final response = await _apiClient.get('$_tasksEndpoint/$userId');
      
      // Parse response into Task objects
      final List<dynamic> taskData = json.decode(response.body);
      return taskData.map((data) => Task.fromJson(data)).toList();
    } catch (e) {
      Logger.error('Error fetching tasks: $e');
      throw Exception('Failed to load tasks: $e');
    }
  }
  
  // Create a new task
  Future<Task> createTask(Task task) async {
    try {
      final response = await _apiClient.post(
        _tasksEndpoint,
        body: json.encode(task.toJson()),
      );
      
      return Task.fromJson(json.decode(response.body));
    } catch (e) {
      Logger.error('Error creating task: $e');
      throw Exception('Failed to create task: $e');
    }
  }
  
  // Update an existing task
  Future<Task> updateTask(String taskId, Map<String, dynamic> updates) async {
    try {
      final response = await _apiClient.patch(
        '$_tasksEndpoint/$taskId',
        body: json.encode(updates),
      );
      
      return Task.fromJson(json.decode(response.body));
    } catch (e) {
      Logger.error('Error updating task: $e');
      throw Exception('Failed to update task: $e');
    }
  }
  
  // Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      await _apiClient.delete('$_tasksEndpoint/$taskId');
    } catch (e) {
      Logger.error('Error deleting task: $e');
      throw Exception('Failed to delete task: $e');
    }
  }
}
