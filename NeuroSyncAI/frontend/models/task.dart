class Task {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime dueDate;
  final Priority priority;
  final DateTime createdAt;
  final String userId;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.isCompleted,
    required this.dueDate,
    required this.priority,
    required this.createdAt,
    required this.userId,
  });

  // Create a copy of the task with updated fields
  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? dueDate,
    Priority? priority,
    DateTime? createdAt,
    String? userId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }

  // Convert Task to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority.name,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
    };
  }

  // Create Task from JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      isCompleted: json['isCompleted'] ?? false,
      dueDate: DateTime.parse(json['dueDate']),
      priority: _priorityFromString(json['priority']),
      createdAt: DateTime.parse(json['createdAt']),
      userId: json['userId'],
    );
  }

  // Helper method to convert string to Priority enum
  static Priority _priorityFromString(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return Priority.high;
      case 'medium':
        return Priority.medium;
      case 'low':
        return Priority.low;
      default:
        return Priority.medium;
    }
  }
}

// Task priority enum
enum Priority {
  high,
  medium,
  low,
}

// Extension for priority color and label
extension PriorityExtension on Priority {
  String get label {
    switch (this) {
      case Priority.high:
        return 'High';
      case Priority.medium:
        return 'Medium';
      case Priority.low:
        return 'Low';
    }
  }
}
