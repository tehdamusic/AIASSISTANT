import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/task.dart';
import 'priority_indicator.dart';

class TaskListItem extends StatelessWidget {
  final Task task;
  final Function(bool) onToggle;
  final VoidCallback onDelete;

  const TaskListItem({
    Key? key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate if task is overdue
    final bool isOverdue = !task.isCompleted && 
                          task.dueDate.isBefore(DateTime.now());

    return Dismissible(
      key: Key(task.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(
            color: task.isCompleted
                ? Colors.green.withOpacity(0.5)
                : isOverdue
                    ? Colors.red.withOpacity(0.5)
                    : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            leading: _buildCheckbox(),
            title: _buildTitle(),
            subtitle: _buildSubtitle(context, isOverdue),
            trailing: PriorityIndicator(priority: task.priority),
          ),
        ),
      ),
    );
  }

  // Checkbox with high contrast for ADHD users
  Widget _buildCheckbox() {
    return Transform.scale(
      scale: 1.3, // Larger checkbox for easier interaction
      child: Checkbox(
        value: task.isCompleted,
        onChanged: (bool? value) {
          if (value != null) {
            onToggle(value);
          }
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.0),
        ),
        checkColor: Colors.white,
        activeColor: Colors.green[700],
        side: BorderSide(
          width: 2,
          color: Colors.grey[600]!,
        ),
      ),
    );
  }

  // Task title with strikethrough if completed
  Widget _buildTitle() {
    return Text(
      task.title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        decoration: task.isCompleted 
            ? TextDecoration.lineThrough 
            : TextDecoration.none,
        color: task.isCompleted 
            ? Colors.grey[600] 
            : Colors.black87,
      ),
    );
  }

  // Task details including due date
  Widget _buildSubtitle(BuildContext context, bool isOverdue) {
    final dateFormat = DateFormat('EEE, MMM d');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (task.description != null && task.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              task.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.event,
              size: 16,
              color: isOverdue ? Colors.red : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              dateFormat.format(task.dueDate),
              style: TextStyle(
                color: isOverdue ? Colors.red : Colors.grey[700],
                fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isOverdue) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red),
                ),
                child: const Text(
                  'OVERDUE',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
