class Message {
  final String id;
  final String content;
  final bool isUserMessage;
  final DateTime timestamp;
  final String userId;

  Message({
    required this.id,
    required this.content,
    required this.isUserMessage,
    required this.timestamp,
    required this.userId,
  });

  // Create a copy of the message with updated fields
  Message copyWith({
    String? id,
    String? content,
    bool? isUserMessage,
    DateTime? timestamp,
    String? userId,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      isUserMessage: isUserMessage ?? this.isUserMessage,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
    );
  }

  // Convert Message to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUserMessage': isUserMessage,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
    };
  }

  // Create Message from JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      content: json['content'],
      isUserMessage: json['isUserMessage'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
      userId: json['userId'],
    );
  }
}
