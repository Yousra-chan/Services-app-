import 'package:flutter/material.dart';
// Only needed for icons
import 'constants.dart'; // Import constants (colors, chatNames)
import 'widgets.dart'; // Import reusable widgets (buildAvatar, buildChatTile, AnimatedChatListItem)

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightGreyBlue,
      appBar: AppBar(
        title: const Text(
          "Chats",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            fontFamily: 'Exo2',
          ),
        ),
        elevation: 0,
        backgroundColor: kPrimaryBlue,
      ),
      body: Column(
        children: [
          // --- Stories/Status/Search Section (Refined Header) ---
          Container(
            height: 110,
            decoration: const BoxDecoration(
              color: kPrimaryBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: chatNames.length + 1,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Call the external helper function
                        buildAvatar(index),
                        // Label text logic
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            index == 0
                                ? "Search"
                                : chatNames[index - 1].split(' ')[0],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontFamily: 'Exo2',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          // --- Chat List Section ---
          const SizedBox(height: 15),
          Expanded(
            child: ListView.separated(
              itemCount: chatNames.length,
              separatorBuilder: (context, index) => const SizedBox(height: 2),
              itemBuilder: (context, index) {
                // Use the external AnimatedChatListItem widget
                return AnimatedChatListItem(
                  index: index,
                  // Call the external helper function for the tile content
                  child: buildChatTile(context, index, chatNames[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
