import 'package:flutter/material.dart';
import '../../models/task.dart';

class PriorityIndicator extends StatelessWidget {
  final Priority priority;
  
  const PriorityIndicator({
    Key? key,
    required this.priority,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getPriorityColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getPriorityColor(),
          width: 1.5,
        ),
      ),
      child: Text(
        priority.label.toUpperCase(),
        style: TextStyle(
          color: _getPriorityColor(),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getPriorityColor() {
    switch (priority) {
      case Priority.high:
        return Colors.red[700]!;
      case Priority.medium:
        return Colors.orange[700]!;
      case Priority.low:
        return Colors.blue[700]!;
    }
  }
}
