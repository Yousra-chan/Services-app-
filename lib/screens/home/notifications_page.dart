// screens/home/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'home_constants.dart'
    hide NotificationItem, NotificationType, FirebaseService;
import 'package:myapp/screens/chat/disscussion/disscussion_page.dart';
import 'package:myapp/ViewModel/chat_view_model.dart';
import 'package:myapp/ViewModel/auth_view_model.dart';
import 'package:myapp/models/NotificationsModel.dart';

class NotificationsWindow extends StatefulWidget {
  const NotificationsWindow({super.key});

  @override
  State<NotificationsWindow> createState() => _NotificationsWindowState();
}

class _NotificationsWindowState extends State<NotificationsWindow> {
  late Stream<List<NotificationItem>> _notificationsStream;
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
          FirebaseService.getUserNotifications(_currentUserId!);
      print('✅ Notifications stream started');
    } else {
      _notificationsStream = Stream.value([]);
      print('❌ User ID is null - cannot load notifications');
    }
  }

  void _markAsRead(String id) {
    print('🔔 Marking notification as read: $id');
    FirebaseService.markNotificationAsRead(id);
  }

  void _navigateToChat(BuildContext context, NotificationItem notification) {
    if (notification.chatId != null && _currentUserId != null) {
      // Mark notification as read
      _markAsRead(notification.id);

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
                  notification.title.replaceAll('New message from ', ''),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.black12, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      color: kDarkTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Exo2',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Notifications List
            Expanded(
              child: StreamBuilder<List<NotificationItem>>(
                stream: _notificationsStream,
                builder: (context, snapshot) {
                  print('🔔 StreamBuilder state: ${snapshot.connectionState}');
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

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _buildNotificationCard(notification, context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
      NotificationItem notification, BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (notification.type == NotificationType.message) {
          _navigateToChat(context, notification);
        } else {
          _markAsRead(notification.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : kUnreadNotificationColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.black12,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon for notifications
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: notification.iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notification.icon,
                color: notification.iconColor,
                size: 16,
              ),
            ),

            // Notification Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Time
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.title,
                              style: TextStyle(
                                color: kDarkTextColor,
                                fontSize: 14,
                                fontWeight: notification.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                                fontFamily: 'Exo2',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              notification.message,
                              style: TextStyle(
                                color: kMutedTextColor,
                                fontSize: 12,
                                fontWeight: notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                                fontFamily: 'Exo2',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatTime(notification.time),
                            style: TextStyle(
                              color: kMutedTextColor,
                              fontSize: 10,
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                              fontFamily: 'Exo2',
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Action Button for specific notification types
                  if (notification.type == NotificationType.message &&
                      notification.actionText.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          _navigateToChat(context, notification);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: kPrimaryBlue.withOpacity(0.1),
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          minimumSize: Size.zero,
                        ),
                        child: Text(
                          notification.actionText,
                          style: TextStyle(
                            color: kPrimaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Exo2',
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
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(kPrimaryBlue),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading notifications...',
            style: TextStyle(
              color: kMutedTextColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_circle,
              color: Colors.red,
              size: 40,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load notifications',
              style: TextStyle(
                color: kDarkTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kMutedTextColor,
                fontSize: 12,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _initializeNotifications,
              child: Text(
                'Retry',
                style: TextStyle(
                  color: kPrimaryBlue,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.bell_slash,
              color: kPrimaryBlue,
              size: 40,
            ),
            const SizedBox(height: 16),
            const Text(
              'You\'re all caught up',
              style: TextStyle(
                color: kDarkTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Exo2',
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Come back later for reminders, health tips, and new messages.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kMutedTextColor,
                  fontSize: 12,
                  fontFamily: 'Exo2',
                ),
              ),
            ),
          ],
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

// How to use it from your home screen:
void showNotificationsWindow(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const NotificationsWindow(),
    barrierColor: Colors.black54,
  );
}
