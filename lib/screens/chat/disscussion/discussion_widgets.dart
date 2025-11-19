import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:myapp/models/MessageModel.dart';
import 'package:myapp/screens/chat/disscussion/disscussion_constants.dart';
import 'package:intl/intl.dart';

Widget buildDiscussionAppBar(
  BuildContext context,
  String contactName,
  bool isOnline,
) {
  final double topPadding = MediaQuery.of(context).padding.top;

  return Container(
    padding: EdgeInsets.fromLTRB(20, topPadding + 15, 20, 15),
    decoration: const BoxDecoration(
      color: kPrimaryBlue,
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
      boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            CupertinoIcons.back,
            color: kLightTextColor,
            size: 28,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: kLightBackgroundColor,
                  child: Icon(
                    CupertinoIcons.person_fill,
                    color: kPrimaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contactName,
                      style: const TextStyle(
                        color: kLightTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Exo2',
                      ),
                    ),
                    Text(
                      isOnline ? "Online" : "Offline",
                      style: TextStyle(
                        color: isOnline ? kOnlineStatusGreen : Colors.white70,
                        fontSize: 13,
                        fontFamily: 'Exo2',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// Builds a single message bubble using MessageModel
Widget buildMessageBubble(MessageModel message, String currentUserId) {
  final bool isSent = message.senderId == currentUserId;

  return Align(
    alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      constraints: const BoxConstraints(maxWidth: 300),
      decoration: BoxDecoration(
        color: isSent ? kOutgoingBubbleColor : kIncomingBubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft:
              isSent ? const Radius.circular(18) : const Radius.circular(5),
          bottomRight:
              isSent ? const Radius.circular(5) : const Radius.circular(18),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            style: TextStyle(
              color: isSent ? kLightTextColor : kDarkTextColor,
              fontSize: 15,
              fontFamily: 'Exo2',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('HH:mm').format(message.timestamp.toDate()),
            style: TextStyle(
              color:
                  isSent ? kLightTextColor.withOpacity(0.7) : kMutedTextColor,
              fontSize: 10,
              fontFamily: 'Exo2',
            ),
          ),
        ],
      ),
    ),
  );
}

// Builds the date separator
Widget buildDateSeparator(String date) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 15),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: kPrimaryBlue.withOpacity(0.1),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Text(
      date,
      style: TextStyle(
        color: kPrimaryBlue,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        fontFamily: 'Exo2',
      ),
    ),
  );
}
