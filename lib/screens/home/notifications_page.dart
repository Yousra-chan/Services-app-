// screens/home/notifications_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:myapp/ViewModel/auth_view_model.dart' show AuthViewModel;
import 'package:myapp/ViewModel/chat_view_model.dart' show ChatViewModel;
import 'package:myapp/screens/chat/disscussion/disscussion_page.dart';
import 'package:provider/provider.dart';
import 'home_screen/home_constants.dart';
import 'package:myapp/services/firebase_service.dart';
import 'package:myapp/models/notification_item.dart';

class NotificationsWindow extends StatefulWidget {
  const NotificationsWindow({super.key});

  @override
  State<NotificationsWindow> createState() => _NotificationsWindowState();
}

class _NotificationsWindowState extends State<NotificationsWindow> {
  late Stream<List<HomeNotificationItem>> _notificationsStream;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() {
    print('🔔 Initializing notifications...');

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    _currentUserId = authViewModel.currentUser?.uid;

    print('🔔 Current User ID: $_currentUserId');

    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      _notificationsStream =
          Stream.periodic(Duration(seconds: 1)) // Polling for testing
              .asyncMap((_) => _fetchNotifications())
              .takeWhile((_) => mounted);
      print('✅ Notifications stream started');
    } else {
      _notificationsStream = Stream.value([]);
      print('❌ User ID is null - cannot load notifications');
    }
  }

  Future<List<HomeNotificationItem>> _fetchNotifications() async {
    try {
      if (_currentUserId == null) return [];

      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('time', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => HomeNotificationItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      return [];
    }
  }

// Update these methods in your notifications_page.dart

  void _markAsReadAndDelete(String id) {
    print('🔔 Deleting notification: $id');

    // Option 1: Direct Firestore delete (recommended for immediate deletion)
    FirebaseFirestore.instance
        .collection('notifications')
        .doc(id)
        .delete()
        .then((_) => print('🗑️ Notification deleted: $id'))
        .catchError((e) => print('❌ Error deleting notification: $e'));
  }

  void _deleteNotificationsForChat(String chatId) {
    if (_currentUserId != null && chatId.isNotEmpty) {
      // Direct Firestore query and delete
      FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: _currentUserId!)
          .where('chatId', isEqualTo: chatId)
          .where('isRead', isEqualTo: false)
          .get()
          .then((snapshot) {
            final batch = FirebaseFirestore.instance.batch();
            for (final doc in snapshot.docs) {
              batch.delete(doc.reference);
            }
            return batch.commit();
          })
          .then((_) => print('🗑️ Deleted notifications for chat: $chatId'))
          .catchError((e) => print('❌ Error deleting notifications: $e'));
    }
  }

// Update your _navigateToChat method to use the new methods:
  void _navigateToChat(
      BuildContext context, HomeNotificationItem notification) {
    if (notification.chatId != null && _currentUserId != null) {
      // Delete this specific notification
      _markAsReadAndDelete(notification.id);

      // Also reset message count for this sender (optional)
      if (notification.senderId != null) {
        FirebaseService.resetMessageCount(
            _currentUserId!, notification.senderId!);
      }

      // Close notifications window
      Navigator.of(context).pop();

      // Navigate to chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider(
            create: (context) => ChatViewModel(userId: _currentUserId!),
            child: DiscussionPage(
              contactName: notification.senderName ??
                  notification.title
                      .replaceAll('New message from ', '')
                      .replaceAll(RegExp(r' \(\d+ new\)'), ''),
              isOnline: true,
              chatId: notification.chatId!,
              currentUserId: _currentUserId!,
              chatViewModel: ChatViewModel(userId: _currentUserId!),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color(0xFFF8F9FF),
              Color(0xFFF0F4FF),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: kPrimaryBlue.withOpacity(0.3),
              blurRadius: 25,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
          ],
          border: Border.all(
            color: kPrimaryBlue.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Vibrant Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kPrimaryBlue,
                    Color(0xFF4A6FDC),
                    Color(0xFF667EEA),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryBlue.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.bell_fill,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Exo2',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(CupertinoIcons.xmark,
                          size: 18, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),

            // Notifications List
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: StreamBuilder<List<HomeNotificationItem>>(
                  stream: _notificationsStream,
                  builder: (context, snapshot) {
                    print(
                        '🔔 StreamBuilder state: ${snapshot.connectionState}');
                    print('🔔 StreamBuilder has error: ${snapshot.hasError}');
                    print('🔔 StreamBuilder has data: ${snapshot.hasData}');

                    if (snapshot.hasError) {
                      print('❌ Stream error: ${snapshot.error}');
                      return _buildErrorState(snapshot.error.toString());
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingState();
                    }

                    final notifications = snapshot.data ?? [];

                    if (notifications.isEmpty) {
                      return _buildEmptyState();
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        setState(() {});
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          return _buildNotificationCard(
                              notification, context, index);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
      HomeNotificationItem notification, BuildContext context, int index) {
    // Color schemes for different notification types
    final colorSchemes = [
      [Color(0xFF667EEA), Color(0xFF764BA2)], // Purple - Message
      [Color(0xFF4FACFE), Color(0xFF00F2FE)], // Blue - Booking
      [Color(0xFF43E97B), Color(0xFF38F9D7)], // Green - Payment
      [Color(0xFFFA709A), Color(0xFFFEE140)], // Orange - Reminder
      [Color(0xFFF093FB), Color(0xFFF5576C)], // Pink - Promotional
      [Color(0xFFA8C0FF), Color(0xFF3F2B96)], // Deep Blue - Rating
      [Color(0xFFFD746C), Color(0xFFFF9068)], // Red-Orange - Health
    ];

    final colors = colorSchemes[notification.type.index % colorSchemes.length];

    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        elevation: notification.isRead ? 2 : 4,
        borderRadius: BorderRadius.circular(16),
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: notification.isRead
                  ? [Colors.white, Color(0xFFF8F9FF)]
                  : [colors[0].withOpacity(0.1), colors[1].withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notification.isRead
                  ? Colors.grey.withOpacity(0.2)
                  : colors[0].withOpacity(0.3),
              width: notification.isRead ? 1 : 1.5,
            ),
            boxShadow: [
              if (!notification.isRead)
                BoxShadow(
                  color: colors[0].withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: GestureDetector(
            onTap: () {
              if (notification.type == HomeNotificationType.message) {
                _navigateToChat(context, notification);
              } else {
                _markAsReadAndDelete(notification.id);
              }
            },
            onLongPress: () {
              // Optional: Show delete confirmation
              _showDeleteDialog(context, notification);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Colorful Icon Container with message count badge
                  Stack(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: colors,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colors[0].withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          notification.icon,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      // Message count badge
                      if (notification.type == HomeNotificationType.message &&
                          notification.messageCount > 1)
                        Positioned(
                          top: -2,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 1.5),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${notification.messageCount}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Notification Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title and Time Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    notification
                                        .formattedTitle, // Use formatted title
                                    style: TextStyle(
                                      color: notification.isRead
                                          ? kDarkTextColor
                                          : colors[0],
                                      fontSize: 14,
                                      fontWeight: notification.isRead
                                          ? FontWeight.w600
                                          : FontWeight.w700,
                                      fontFamily: 'Exo2',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notification.message,
                                    style: TextStyle(
                                      color: notification.isRead
                                          ? kMutedTextColor
                                          : colors[0].withOpacity(0.8),
                                      fontSize: 12,
                                      fontWeight: notification.isRead
                                          ? FontWeight.normal
                                          : FontWeight.w500,
                                      fontFamily: 'Exo2',
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: notification.isRead
                                        ? Colors.grey.withOpacity(0.1)
                                        : colors[0].withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _formatTime(notification.lastMessageTime),
                                    style: TextStyle(
                                      color: notification.isRead
                                          ? kMutedTextColor
                                          : colors[0],
                                      fontSize: 9,
                                      fontWeight: notification.isRead
                                          ? FontWeight.normal
                                          : FontWeight.w500,
                                      fontFamily: 'Exo2',
                                    ),
                                  ),
                                ),
                                if (!notification.isRead)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'NEW',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 7,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'Exo2',
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),

                        // Action Button for specific notification types
                        if (notification.type == HomeNotificationType.message &&
                            notification.actionText.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: SizedBox(
                              width: double.infinity,
                              child: Material(
                                borderRadius: BorderRadius.circular(8),
                                elevation: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: colors,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colors[0].withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextButton(
                                    onPressed: () {
                                      _navigateToChat(context, notification);
                                    },
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6, horizontal: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      minimumSize: Size.zero,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          notification.actionText,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Exo2',
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, HomeNotificationItem notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content:
            const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _markAsReadAndDelete(notification.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimaryBlue, Color(0xFF667EEA)],
              ),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading notifications...',
            style: TextStyle(
              color: kPrimaryBlue,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Exo2',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Getting your latest updates',
            style: TextStyle(
              color: kMutedTextColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFD746C), Color(0xFFFF9068)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.exclamationmark_circle_fill,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Oops!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Exo2',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error loading notifications',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF667EEA).withOpacity(0.1),
                  Color(0xFF764BA2).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: kPrimaryBlue.withOpacity(0.1),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimaryBlue, Color(0xFF667EEA)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryBlue.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.bell_slash,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'All Caught Up! 🎉',
                  style: TextStyle(
                    color: kDarkTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Exo2',
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'No new notifications right now. You\'re all up to date with your messages, reminders, and updates.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kMutedTextColor,
                      fontSize: 13,
                      fontFamily: 'Exo2',
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kPrimaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Come back later for updates',
                    style: TextStyle(
                      color: kPrimaryBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return '1d';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo';
    } else {
      return '1yr';
    }
  }
}

void showNotificationsWindow(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return Material(
        type: MaterialType.transparency, // THIS IS KEY
        child: Center(
          child: Container(
            margin: EdgeInsets.all(20),
            child: NotificationsWindow(),
          ),
        ),
      );
    },
    barrierColor: Colors.transparent,
  );
}
