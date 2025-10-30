import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'constants.dart';
import 'package:myapp/screens/chat/disscussion/disscussion_page.dart';

// --- Reusable Widget Builders ---

// Helper method for the horizontal Avatar/Search bar (used in the header)
Widget buildAvatar(int index) {
  bool isSearchIcon = index == 0;
  return Container(
    width: 55,
    height: 55,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: isSearchIcon ? Colors.transparent : Colors.white54,
        width: 2.5,
      ),
      boxShadow: [
        BoxShadow(
          color: kSoftShadowColor.withOpacity(isSearchIcon ? 0.0 : 0.4),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: CircleAvatar(
      radius: 25,
      backgroundColor: isSearchIcon ? Colors.white : kLightGreyBlue,
      child: Icon(
        isSearchIcon ? CupertinoIcons.search : CupertinoIcons.person_fill,
        color: kPrimaryBlue,
        size: 26,
      ),
    ),
  );
}

// Helper method for the individual chat tile (used in the ListView)
Widget buildChatTile(BuildContext context, int index, String chatName) {
  final bool isUnread = index % 3 == 0;

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white, // Tile background is white
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: kSoftShadowColor.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      leading: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: kLightGreyBlue,
            child: Icon(
              CupertinoIcons.person_fill,
              color: kPrimaryBlue,
              size: 30,
            ),
          ),
          if (index % 2 == 0)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.greenAccent[400],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        chatName,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isUnread ? FontWeight.w900 : FontWeight.w700,
          color: kPrimaryBlue,
          fontFamily: 'Exo2',
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          isUnread
              ? "New message: You won't believe..."
              : "Hey, I'll send the files by end of day.",
          style: TextStyle(
            fontSize: 13,
            color: isUnread ? kPrimaryBlue.withOpacity(0.8) : Colors.grey[600],
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'Exo2',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            "Yesterday",
            style: TextStyle(
              fontSize: 11,
              color: isUnread ? kPrimaryBlue : Colors.grey[500],
              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'Exo2',
            ),
          ),
          const SizedBox(height: 6),
          if (isUnread)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              constraints: const BoxConstraints(minWidth: 20),
              decoration: BoxDecoration(
                color: kPrimaryBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "${index + 1}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Exo2',
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    DiscussionPage(contactName: "Molly Clark", isOnline: true),
          ),
        );
      },
    ),
  );
}

// --- Animation Widget ---

// Widget that provides a slide-up and fade-in animation for list items.
class AnimatedChatListItem extends StatefulWidget {
  final Widget child;
  final int index;

  const AnimatedChatListItem({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  // Note the state class name is now public: _AnimatedChatListItemState
  State<AnimatedChatListItem> createState() => _AnimatedChatListItemState();
}

class _AnimatedChatListItemState extends State<AnimatedChatListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    final delay = Duration(milliseconds: 50 * widget.index);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Staggered animation effect using Future.delayed
    Future.delayed(delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(opacity: _fadeAnimation, child: widget.child),
    );
  }
}
