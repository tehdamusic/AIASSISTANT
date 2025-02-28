import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const MessageBubble({
    Key? key,
    required this.message,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isUserMessage = message.isUserMessage;
    final timeFormat = DateFormat('h:mm a');
    
    return Padding(
      padding: EdgeInsets.only(
        top: isFirstInGroup ? 8.0 : 2.0,
        bottom: isLastInGroup ? 8.0 : 2.0,
        left: isUserMessage ? 64.0 : 16.0,
        right: isUserMessage ? 16.0 : 64.0,
      ),
      child: Column(
        crossAxisAlignment:
            isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender name - only show for first message in group
          if (isFirstInGroup)
            Padding(
              padding: const EdgeInsets.only(
                left: 12.0,
                bottom: 4.0,
              ),
              child: Text(
                isUserMessage ? 'You' : 'AI Assistant',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
          
          // Message bubble
          Container(
            decoration: BoxDecoration(
              color: isUserMessage
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(
                  isUserMessage ? 16 : (isLastInGroup ? 4 : 16)),
                bottomRight: Radius.circular(
                  isUserMessage ? (isLastInGroup ? 4 : 16) : 16),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message content
                Text(
                  message.content,
                  style: TextStyle(
                    fontSize: 16,
                    color: isUserMessage 
                        ? Colors.white 
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                
                // Timestamp
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    timeFormat.format(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: isUserMessage 
                          ? Colors.white.withOpacity(0.7) 
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
