import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/message.dart';
import '../services/api/chat_api.dart';
import '../services/local/shared_prefs_service.dart';

// Chat state class
class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final String? error;

  ChatState({
    required this.messages,
    this.isLoading = false,
    this.error,
  });

  // Create initial state
  factory ChatState.initial() {
    return ChatState(
      messages: [],
      isLoading: false,
      error: null,
    );
  }

  // Create loading state
  ChatState copyWithLoading() {
    return ChatState(
      messages: this.messages,
      isLoading: true,
      error: null,
    );
  }

  // Create error state
  ChatState copyWithError(String errorMessage) {
    return ChatState(
      messages: this.messages,
      isLoading: false,
      error: errorMessage,
    );
  }

  // Create success state with messages
  ChatState copyWithMessages(List<Message> newMessages) {
    return ChatState(
      messages: newMessages,
      isLoading: false,
      error: null,
    );
  }

  // Add a single message
  ChatState copyWithNewMessage(Message newMessage) {
    return ChatState(
      messages: [...this.messages, newMessage],
      isLoading: false,
      error: null,
    );
  }
}

// Chat notifier for state updates
class ChatNotifier extends StateNotifier<ChatState> {
  final ChatApi _chatApi;
  final SharedPrefsService _prefs;
  final Uuid _uuid = const Uuid();

  ChatNotifier(this._chatApi, this._prefs) : super(ChatState.initial());

  // Load messages from API
  Future<void> loadMessages() async {
    state = state.copyWithLoading();

    try {
      final userId = await _prefs.getUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final messages = await _chatApi.getMessages(userId);
      state = state.copyWithMessages(messages);
    } catch (e) {
      state = state.copyWithError(e.toString());
    }
  }

  // Send message to AI
  Future<void> sendMessage(String content) async {
    // Get user ID
    final userId = await _prefs.getUserId();
    if (userId == null) {
      state = state.copyWithError('User ID not found');
      return;
    }

    // Create user message
    final userMessage = Message(
      id: _uuid.v4(),
      content: content,
      isUserMessage: true,
      timestamp: DateTime.now(),
      userId: userId,
    );

    // Add user message to state
    state = state.copyWithNewMessage(userMessage);

    // Set loading state for AI response
    state = state.copyWithLoading();

    try {
      // Send message to API
      final aiResponse = await _chatApi.sendMessage(userMessage);
      
      // Add AI response to state
      state = state.copyWithNewMessage(aiResponse);
    } catch (e) {
      state = state.copyWithError('Failed to get AI response: ${e.toString()}');
    }
  }

  // Clear chat history
  Future<void> clearMessages() async {
    try {
      final userId = await _prefs.getUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      await _chatApi.clearMessages(userId);
      state = ChatState.initial();
    } catch (e) {
      state = state.copyWithError(e.toString());
    }
  }
}

// Chat API provider
final chatApiProvider = Provider<ChatApi>((ref) => ChatApi());

// Shared prefs provider
final sharedPrefsProvider = Provider<SharedPrefsService>((ref) => SharedPrefsService());

// Chat provider
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final chatApi = ref.watch(chatApiProvider);
  final prefs = ref.watch(sharedPrefsProvider);
  return ChatNotifier(chatApi, prefs);
});
