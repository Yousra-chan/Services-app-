import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/ViewModel/chat_view_model.dart';
import 'package:myapp/models/MessageModel.dart';
import 'package:myapp/screens/chat/disscussion/disscussion_constants.dart';
import 'package:myapp/screens/chat/disscussion/discussion_widgets.dart';
import 'package:intl/intl.dart';
import 'package:myapp/utils/image_utils.dart';
import 'package:http/http.dart' as http;

class DiscussionPage extends StatefulWidget {
  final String contactName;
  final bool isOnline;
  final String chatId;
  final String currentUserId;
  final ChatViewModel chatViewModel;
  final String? profileImageUrl;

  const DiscussionPage({
    super.key,
    required this.contactName,
    required this.isOnline,
    required this.chatId,
    required this.currentUserId,
    required this.chatViewModel,
    this.profileImageUrl,
  });

  @override
  State<DiscussionPage> createState() => _DiscussionPageState();
}

class _DiscussionPageState extends State<DiscussionPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<MessageModel> _messages = [];
  StreamSubscription? _messagesSubscription;
  String? _currentUserProfileImageUrl;
  String? _contactProfileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadProfileImages();
    _messageController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _loadMessages() {
    _messagesSubscription =
        widget.chatViewModel.listenMessages(widget.chatId).listen((messages) {
      if (mounted) {
        setState(() {
          _messages = messages;
        });
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

// With proper error handling:
  void _loadProfileImages() async {
    try {
      // Load current user's profile image
      final currentUserImage = await widget.chatViewModel
          .getUserProfileImageUrl(widget.currentUserId);
      if (mounted) {
        setState(() {
          _currentUserProfileImageUrl = currentUserImage;
        });
      }

      // Load contact's profile image if not provided
      if (widget.profileImageUrl == null || widget.profileImageUrl!.isEmpty) {
        // Extract contact ID from chatId (chatId format: "id1_id2")
        final participants = widget.chatId.split('_');
        final otherUserId = participants.firstWhere(
            (id) => id != widget.currentUserId,
            orElse: () => participants.isNotEmpty ? participants[0] : '');

        if (otherUserId.isNotEmpty) {
          final contactImage =
              await widget.chatViewModel.getUserProfileImageUrl(otherUserId);
          if (mounted) {
            setState(() {
              _contactProfileImageUrl = contactImage;
            });
          }
        }
      } else {
        // Use the provided profile image
        if (mounted) {
          setState(() {
            _contactProfileImageUrl = widget.profileImageUrl;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading profile images: $e');
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

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

  Future<bool> _checkImageValidity(String imageUrl) async {
    try {
      if (ImageUtils.isNetworkImage(imageUrl)) {
        final response = await http.head(Uri.parse(imageUrl));
        return response.statusCode == 200;
      } else if (ImageUtils.isBase64Image(imageUrl)) {
        final bytes = ImageUtils.decodeBase64Image(imageUrl);
        return bytes != null && bytes.isNotEmpty;
      }
      return false;
    } catch (e) {
      print('❌ Image validation error: $e');
      return false;
    }
  }

  Widget _buildContactAvatar(String? profileImageUrl, String contactName) {
    // Use the loaded contact profile image or fallback to provided one
    final imageUrl = _contactProfileImageUrl ?? profileImageUrl;
    final imageProvider = ImageUtils.getImageProvider(imageUrl);
    final String displayInitial =
        contactName.isNotEmpty ? contactName[0].toUpperCase() : '?';

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white54,
          width: 2,
        ),
      ),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white.withOpacity(0.2),
        backgroundImage: imageProvider,
        child: imageProvider == null
            ? Text(
                displayInitial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              )
            : _buildAvatarLoadingFallback(imageUrl!, displayInitial),
      ),
    );
  }

  Widget _buildAvatarLoadingFallback(String imageUrl, String fallbackInitial) {
    return FutureBuilder<bool>(
      future: _checkImageValidity(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          );
        }

        if (snapshot.hasError || !(snapshot.data ?? false)) {
          return Text(
            fallbackInitial,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          );
        }

        return Container();
      },
    );
  }

  Widget _buildDiscussionAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 15,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 12, 94, 153),
            Color(0xFF4A6FDC),
            Color(0xFF667EEA),
            Color(0xFF764BA2),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(
              CupertinoIcons.back,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),

          const SizedBox(width: 12),

          // Enhanced contact avatar with base64 support
          _buildContactAvatar(widget.profileImageUrl, widget.contactName),

          const SizedBox(width: 12),

          // Contact info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contactName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Exo2',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color:
                            widget.isOnline ? Colors.greenAccent : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontFamily: 'Exo2',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons
          IconButton(
            icon: const Icon(
              CupertinoIcons.video_camera_solid,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              CupertinoIcons.phone_solid,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              CupertinoIcons.ellipsis_vertical,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMessageAvatar(bool isCurrentUser) {
    final profileImageUrl =
        isCurrentUser ? _currentUserProfileImageUrl : _contactProfileImageUrl;
    final imageProvider = ImageUtils.getImageProvider(profileImageUrl);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: kPrimaryBlue.withOpacity(0.1),
        backgroundImage: imageProvider,
        child: imageProvider == null
            ? Icon(
                CupertinoIcons.person_fill,
                color: kPrimaryBlue,
                size: 18,
              )
            : _buildMessageAvatarLoadingFallback(profileImageUrl!),
      ),
    );
  }

  Widget _buildMessageAvatarLoadingFallback(String imageUrl) {
    return FutureBuilder<bool>(
      future: _checkImageValidity(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(kPrimaryBlue),
          );
        }

        if (snapshot.hasError || !(snapshot.data ?? false)) {
          return Icon(
            CupertinoIcons.person_fill,
            color: kPrimaryBlue,
            size: 18,
          );
        }

        return Container();
      },
    );
  }

  Widget _buildCurrentUserAvatar() {
    final imageProvider =
        ImageUtils.getImageProvider(_currentUserProfileImageUrl);

    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: CircleAvatar(
        radius: 14,
        backgroundColor: Colors.transparent,
        backgroundImage: imageProvider,
        child: imageProvider == null
            ? Icon(
                CupertinoIcons.person_fill,
                color: Colors.white,
                size: 14,
              )
            : null,
      ),
    );
  }

  Widget _buildEnhancedMessageBubble(MessageModel message) {
    final bool isMe = message.senderId == widget.currentUserId;
    final bool showAvatar = !isMe;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (showAvatar) ...[
            _buildMessageAvatar(false), // Contact's avatar
            const SizedBox(width: 8),
          ],

          // Message bubble
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isMe
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF667EEA),
                              Color(0xFF764BA2),
                            ],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.grey.shade100,
                              Colors.grey.shade200,
                            ],
                          ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isMe
                          ? const Radius.circular(20)
                          : const Radius.circular(4),
                      bottomRight: isMe
                          ? const Radius.circular(4)
                          : const Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isMe ? Colors.white : kDarkTextColor,
                      fontSize: 16,
                      fontFamily: 'Exo2',
                    ),
                  ),
                ),

                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                  child: Text(
                    _formatMessageTime(message.timestamp),
                    style: TextStyle(
                      color: kMutedTextColor,
                      fontSize: 11,
                      fontFamily: 'Exo2',
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (isMe) ...[
            const SizedBox(width: 8),
            // Current user's avatar (smaller, optional)
            _buildCurrentUserAvatar(),
          ],
        ],
      ),
    );
  }

  String _formatMessageTime(dynamic timestamp) {
    final messageTime = _getMessageDate(timestamp);
    return DateFormat('HH:mm').format(messageTime);
  }

  @override
  Widget build(BuildContext context) {
    final groupedMessages = _groupMessagesByDay(_messages);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Enhanced Header with base64 support
          _buildDiscussionAppBar(),

          // Messages Area
          Expanded(
            child: Container(
              color: Colors.white,
              child: _messages.isEmpty
                  ? _EmptyChatState(contactName: widget.contactName)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      itemCount: groupedMessages.keys.length,
                      itemBuilder: (context, dayIndex) {
                        String day = groupedMessages.keys.elementAt(dayIndex);
                        List<MessageModel> dailyMessages =
                            groupedMessages[day]!;

                        return Column(
                          children: [
                            _buildCleanDateSeparator(day),
                            ...dailyMessages.map(
                              (message) => _buildEnhancedMessageBubble(message),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ),

          // Input Field
          _buildCleanMessageInput(),
        ],
      ),
    );
  }

  Widget _buildCleanDateSeparator(String date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: kPrimaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        date,
        style: TextStyle(
          color: kPrimaryBlue,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: 'Exo2',
        ),
      ),
    );
  }

  Widget _buildCleanMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment button
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade100,
              ),
              child: Icon(
                CupertinoIcons.paperclip,
                color: kPrimaryBlue,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            // Message input field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontFamily: 'Exo2',
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        style: TextStyle(
                          color: kDarkTextColor,
                          fontFamily: 'Exo2',
                          fontSize: 16,
                        ),
                        maxLines: 5,
                        minLines: 1,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),

                    // Emoji button
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade100,
                        ),
                        child: Icon(
                          CupertinoIcons.smiley,
                          color: Colors.grey.shade600,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Send button
            GestureDetector(
              onTap:
                  _messageController.text.trim().isEmpty ? null : _sendMessage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: _messageController.text.trim().isEmpty
                      ? null
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF667EEA),
                            Color(0xFF764BA2),
                          ],
                        ),
                  color: _messageController.text.trim().isEmpty
                      ? Colors.grey.shade300
                      : null,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.arrow_up,
                  color: _messageController.text.trim().isEmpty
                      ? Colors.grey.shade500
                      : Colors.white,
                  size: 20,
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

class _EmptyChatState extends StatelessWidget {
  final String contactName;

  const _EmptyChatState({required this.contactName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: kPrimaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              color: kPrimaryBlue,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Start the conversation',
            style: TextStyle(
              color: kDarkTextColor,
              fontFamily: 'Exo2',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send your first message to $contactName',
            style: TextStyle(
              color: kMutedTextColor,
              fontFamily: 'Exo2',
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
