import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/ViewModel/chat_view_model.dart';
import 'package:myapp/models/MessageModel.dart';
import 'package:myapp/screens/chat/disscussion/disscussion_constants.dart';
import 'package:myapp/screens/chat/disscussion/discussion_widgets.dart';
import 'package:intl/intl.dart';

class DiscussionPage extends StatefulWidget {
  final String contactName;
  final bool isOnline;
  final String chatId;
  final String currentUserId;
  final ChatViewModel chatViewModel;

  const DiscussionPage({
    super.key,
    required this.contactName,
    required this.isOnline,
    required this.chatId,
    required this.currentUserId,
    required this.chatViewModel,
  });

  @override
  State<DiscussionPage> createState() => _DiscussionPageState();
}

class _DiscussionPageState extends State<DiscussionPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<MessageModel> _messages = [];
  StreamSubscription? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() {
    // Use the passed view model instead of Provider.of
    _messagesSubscription =
        widget.chatViewModel.listenMessages(widget.chatId).listen((messages) {
      if (mounted) {
        setState(() {
          _messages = messages;
        });

        // Scroll to bottom after messages are loaded
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients && _messages.isNotEmpty) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    // Use the passed view model instead of Provider.of
    final newMessage = MessageModel(
      senderId: widget.currentUserId,
      text: _messageController.text.trim(),
      timestamp: Timestamp.now(),
      type: 'text',
    );

    final success =
        await widget.chatViewModel.sendMessage(widget.chatId, newMessage);

    if (success && mounted) {
      _messageController.clear();

      // Scroll to bottom after sending message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  DateTime _getMessageDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is DateTime) {
      return timestamp;
    } else {
      return DateTime.now();
    }
  }

  Map<String, List<MessageModel>> _groupMessagesByDay(
      List<MessageModel> messages) {
    Map<String, List<MessageModel>> groupedMessages = {};

    for (var message in messages) {
      final messageDate = _getMessageDate(message.timestamp);

      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      String day;
      if (messageDate.year == today.year &&
          messageDate.month == today.month &&
          messageDate.day == today.day) {
        day = "Today";
      } else if (messageDate.year == yesterday.year &&
          messageDate.month == yesterday.month &&
          messageDate.day == yesterday.day) {
        day = "Yesterday";
      } else {
        day = DateFormat('MMM d, yyyy').format(messageDate);
      }

      if (!groupedMessages.containsKey(day)) {
        groupedMessages[day] = [];
      }
      groupedMessages[day]!.add(message);
    }

    return groupedMessages;
  }

  @override
  Widget build(BuildContext context) {
    final groupedMessages = _groupMessagesByDay(_messages);

    return Scaffold(
      backgroundColor: kLightBackgroundColor,
      body: Column(
        children: [
          buildDiscussionAppBar(context, widget.contactName, widget.isOnline),
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'Start the conversation...',
                      style: TextStyle(
                        color: kMutedTextColor,
                        fontFamily: 'Exo2',
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: groupedMessages.keys.length,
                    itemBuilder: (context, dayIndex) {
                      String day = groupedMessages.keys.elementAt(dayIndex);
                      List<MessageModel> dailyMessages = groupedMessages[day]!;

                      return Column(
                        children: [
                          buildDateSeparator(day),
                          ...dailyMessages.map(
                            (message) => buildMessageBubble(
                              message,
                              widget.currentUserId,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          _buildMessageInputField(),
        ],
      ),
    );
  }

  Widget _buildMessageInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: kCardBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: "Type Your Message",
                  hintStyle: const TextStyle(
                    color: kMutedTextColor,
                    fontFamily: 'Exo2',
                  ),
                  filled: true,
                  fillColor: kLightBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(
                  color: kDarkTextColor,
                  fontFamily: 'Exo2',
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kPrimaryBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.arrow_up,
                  color: kLightTextColor,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
