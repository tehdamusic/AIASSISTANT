import 'dart:convert';
import 'package:uuid/uuid.dart';

import '../../models/message.dart';
import '../../utils/logger.dart';
import 'api_client.dart';

class ChatApi {
  final ApiClient _apiClient = ApiClient();
  final Uuid _uuid = const Uuid();
  
  // Endpoint for chat
  static const String _chatEndpoint = '/chat';
  
  // Get chat history for user
  Future<List<Message>> getMessages(String userId) async {
    try {
      final response = await _apiClient.get('$_chatEndpoint/$userId');
      
      // Parse response into Message objects
      final List<dynamic> messageData = json.decode(response.body);
      return messageData.map((data) => Message.fromJson(data)).toList();
    } catch (e) {
      Logger.error('Error fetching messages: $e');
      throw Exception('Failed to load messages: $e');
    }
  }
  
  // Send message to AI and get response
  Future<Message> sendMessage(Message userMessage) async {
    try {
      final response = await _apiClient.post(
        _chatEndpoint,
        body: json.encode({
          'userId': userMessage.userId,
          'content': userMessage.content,
        }),
      );
      
      final responseData = json.decode(response.body);
      
      // Create AI message from response
      return Message(
        id: _uuid.v4(),
        content: responseData['response'],
        isUserMessage: false,
        timestamp: DateTime.now(),
        userId: userMessage.userId,
      );
    } catch (e) {
      Logger.error('Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }
  
  // Clear chat history for user
  Future<void> clearMessages(String userId) async {
    try {
      await _apiClient.delete('$_chatEndpoint/$userId');
    } catch (e) {
      Logger.error('Error clearing messages: $e');
      throw Exception('Failed to clear messages: $e');
    }
  }
}
