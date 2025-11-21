import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/ChatModel.dart';
import '../models/MessageModel.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  late Stream<List<ChatModel>> _userChatsStream;
  Stream<List<ChatModel>> get userChatsStream => _userChatsStream;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String? _currentUserId;

  ChatViewModel({required String userId}) {
    _currentUserId = userId;
    _initializeStream(userId);
  }

  void _initializeStream(String userId) {
    _userChatsStream = _chatService.getUserChatsStream(userId);
    notifyListeners();
  }

  void updateUser(String newUserId) {
    _currentUserId = newUserId;
    _initializeStream(newUserId);
  }

  Stream<List<MessageModel>> listenMessages(String chatId) {
    if (_currentUserId == null) {
      throw Exception('User ID not defined');
    }
    return _chatService.listenMessages(chatId, currentUserId: _currentUserId!);
  }

  Future<bool> sendMessage(String chatId, MessageModel message) async {
    _setLoading(true);
    _setError(null);

    try {
      await _chatService.sendMessage(chatId, message);
      return true;
    } catch (e) {
      _setError('Error sending message: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> createChat({
    required String clientId,
    required String providerId,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final chatId = await _chatService.createChat(
        clientId: clientId,
        providerId: providerId,
      );
      return chatId;
    } catch (e) {
      _setError('Error creating chat: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableProviders() async {
    _setLoading(true);
    try {
      return await _chatService.getAvailableProviders();
    } catch (e) {
      _setError('Error loading providers: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  Stream<int> getUnreadCount(String chatId) {
    if (_currentUserId == null) {
      throw Exception('User ID not defined');
    }
    return _chatService.getUnreadCount(chatId, _currentUserId!);
  }

  Stream<int> getTotalUnreadCount() {
    if (_currentUserId == null) {
      throw Exception('User ID not defined');
    }
    return _chatService.getTotalUnreadCount(_currentUserId!);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
