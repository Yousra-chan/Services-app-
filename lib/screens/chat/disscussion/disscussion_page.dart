import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:myapp/screens/chat/disscussion/disscussion_constants.dart';
import 'discussion_widgets.dart'; // Reusable UI components

class DiscussionPage extends StatefulWidget {
  final String contactName;
  final bool isOnline;

  const DiscussionPage({
    super.key,
    required this.contactName,
    this.isOnline = true,
  });

  @override
  State<DiscussionPage> createState() => _DiscussionPageState();
}

class _DiscussionPageState extends State<DiscussionPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Use a mutable list initialized with dummy data
  late List<Message> _messages;

  @override
  void initState() {
    super.initState();
    // Copy the dummy data to a mutable list
    _messages = List.from(dummyMessages);

    // Initial scroll to the bottom (needs a small delay for ListView to render)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  // Logic to send a new message
  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        _messages.add(
          Message(
            text: _messageController.text.trim(),
            time: "Now",
            type: MessageType.sent,
          ),
        );
      });
      _messageController.clear();
      // Scroll to the bottom after sending a message
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Logic to group messages by day for the timestamp separator
  Map<String, List<Message>> _groupMessagesByDay(List<Message> messages) {
    Map<String, List<Message>> groupedMessages = {};
    for (var message in messages) {
      // Simplified grouping logic: checks for 'Yesterday' or defaults to 'Today'
      String day = message.time.contains("Yesterday") ? "Yesterday" : "Today";
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
          // 1. Custom AppBar (from discussion_widgets.dart)
          buildDiscussionAppBar(context, widget.contactName, widget.isOnline),

          // 2. Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: groupedMessages.keys.length,
              itemBuilder: (context, dayIndex) {
                String day = groupedMessages.keys.elementAt(dayIndex);
                List<Message> dailyMessages = groupedMessages[day]!;

                return Column(
                  children: [
                    // Date Separator (from discussion_widgets.dart)
                    buildDateSeparator(day),
                    // Messages for the day (using buildMessageBubble from discussion_widgets.dart)
                    ...dailyMessages.map(
                      (message) => buildMessageBubble(message),
                    ),
                  ],
                );
              },
            ),
          ),

          // 3. Message Input Field
          _buildMessageInputField(),
        ],
      ),
    );
  }

  // Builds the message input field at the bottom (kept here because it manages the controller/state)
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
            // Text Input Field
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
                  // The contentPadding here determines the vertical spacing inside the TextField.
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical:
                        12, // This ensures text is centered vertically within the TextField itself.
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

            // Send Button
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
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
