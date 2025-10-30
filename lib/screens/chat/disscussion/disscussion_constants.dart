import 'package:flutter/material.dart';

// --- Global Constants (Consistent with previous screens) ---
// Primary Blue (Vibrant from the image)
const Color kPrimaryBlue = Color.fromARGB(255, 12, 94, 153);
// Light Background Color for the message bubbles and overall page body.
const Color kLightBackgroundColor = Color.fromARGB(255, 248, 249, 255);
// Color for incoming message bubbles
const Color kIncomingBubbleColor = Color.fromARGB(255, 230, 230, 230);
// Color for outgoing message bubbles
const Color kOutgoingBubbleColor = kPrimaryBlue;
// Text Colors
const Color kDarkTextColor = Color.fromARGB(255, 50, 50, 50);
const Color kLightTextColor = Colors.white;
const Color kMutedTextColor = Color.fromARGB(255, 150, 150, 150);
const Color kOnlineStatusGreen = Color.fromARGB(255, 76, 175, 80);
// Pure white for high contrast input field area
const Color kCardBackgroundColor = Colors.white;

// --- Message Data Model ---
enum MessageType { sent, received }

class Message {
  final String text;
  final String time;
  final MessageType type;

  Message({required this.text, required this.time, required this.type});
}

// --- Dummy Message Data for the discussion ---
final List<Message> dummyMessages = [
  Message(
    text: "Hi Ankur! What's Up?",
    time: "Yesterday 14:30 PM",
    type: MessageType.received,
  ),
  Message(
    text: "Oh, Hello! It's perfectly fine I'm just heading out for sometime",
    time: "Yesterday 14:35 PM",
    type: MessageType.sent,
  ),
  Message(
    text: "Sure! I'll be there this weekend with my buddies",
    time: "Yesterday 14:40 PM",
    type: MessageType.sent,
  ),
  Message(
    text: "Yes I Am So Happy 😊",
    time: "Yesterday 14:30 PM",
    type: MessageType.received,
  ),
  Message(
    text: "Let's meet tomorrow?",
    time: "Today 10:00 AM",
    type: MessageType.sent,
  ),
  Message(
    text: "Sounds good! How about lunch?",
    time: "Today 10:05 AM",
    type: MessageType.received,
  ),
  Message(
    text: "Perfect! See you at 1 PM.",
    time: "Today 10:10 AM",
    type: MessageType.sent,
  ),
];
