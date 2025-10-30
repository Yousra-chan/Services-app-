import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../models/chatmodel.dart';
import '../models/messagemodel.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  // Streams
  Stream<List<ChatModel>>? _userChatsStream;
  Stream<List<ChatModel>>? get userChatsStream => _userChatsStream;

  // Local state for loading and error
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  ChatViewModel({required String userId}) {
    _initializeStream(userId);
  }

  // Initialize or refresh the stream for a given user
  void _initializeStream(String userId) {
    _userChatsStream = _chatService.getUserChatsStream(userId);
    notifyListeners();
  }

  // Optionally allow switching users dynamically
  void updateUser(String newUserId) {
    _initializeStream(newUserId);
  }

  // Listen to messages in a specific chat
  Stream<List<MessageModel>> listenMessages(String chatId) {
    return _chatService.listenMessages(chatId);
  }

  // Send a message with safe error handling
  Future<void> sendMessage(String chatId, MessageModel message) async {
    _setLoading(true);
    try {
      await _chatService.sendMessage(chatId, message);
    } catch (e) {
      _setError('Failed to send message: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create a new chat between client and provider
  Future<void> createChat({
    required String clientId,
    required String providerId,
    required DocumentReference clientRef,
    required DocumentReference providerRef,
  }) async {
    _setLoading(true);
    try {
      await _chatService.createChat(
        clientId: clientId,
        providerId: providerId,
        clientRef: clientRef,
        providerRef: providerRef,
      );
    } catch (e) {
      _setError('Failed to create chat: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Internal helpers for managing state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }
}
