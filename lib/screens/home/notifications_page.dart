// screens/home/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:myapp/ViewModel/auth_view_model.dart' show AuthViewModel;
import 'package:myapp/ViewModel/chat_view_model.dart' show ChatViewModel;
import 'package:myapp/screens/chat/disscussion/disscussion_page.dart';
import 'package:provider/provider.dart';
import 'home_screen/home_constants.dart';
import 'package:myapp/services/firebase_service.dart'; // ADD THIS
import 'package:myapp/models/notification_item.dart'; // ADD THIS

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

  void _navigateToChat(
      BuildContext context, HomeNotificationItem notification) {
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

                    // In the StreamBuilder, update the ListView padding
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8), // Reduced vertical padding
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _buildNotificationCard(
                            notification, context, index);
                      },
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
      margin: const EdgeInsets.only(bottom: 8), // Reduced from 12
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
                _markAsRead(notification.id);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12), // Reduced from 16
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Colorful Icon Container
                  Container(
                    width: 40, // Reduced from 48
                    height: 40, // Reduced from 48
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
                      size: 18, // Reduced from 20
                    ),
                  ),

                  // Notification Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min, // ADD THIS
                      children: [
                        // Title and Time Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min, // ADD THIS
                                children: [
                                  Text(
                                    notification.title,
                                    style: TextStyle(
                                      color: notification.isRead
                                          ? kDarkTextColor
                                          : colors[0],
                                      fontSize: 14, // Reduced from 15
                                      fontWeight: notification.isRead
                                          ? FontWeight.w600
                                          : FontWeight.w700, // Reduced from 800
                                      fontFamily: 'Exo2',
                                    ),
                                    maxLines: 1, // ADD THIS
                                    overflow: TextOverflow.ellipsis, // ADD THIS
                                  ),
                                  const SizedBox(height: 4), // Reduced from 6
                                  Text(
                                    notification.message,
                                    style: TextStyle(
                                      color: notification.isRead
                                          ? kMutedTextColor
                                          : colors[0].withOpacity(0.8),
                                      fontSize: 12, // Reduced from 13
                                      fontWeight: notification.isRead
                                          ? FontWeight.normal
                                          : FontWeight.w500, // Reduced from 600
                                      fontFamily: 'Exo2',
                                      height: 1.2, // Reduced from 1.3
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
                              mainAxisSize: MainAxisSize.min, // ADD THIS
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3), // Reduced
                                  decoration: BoxDecoration(
                                    color: notification.isRead
                                        ? Colors.grey.withOpacity(0.1)
                                        : colors[0].withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _formatTime(notification.time),
                                    style: TextStyle(
                                      color: notification.isRead
                                          ? kMutedTextColor
                                          : colors[0],
                                      fontSize: 9, // Reduced from 10
                                      fontWeight: notification.isRead
                                          ? FontWeight.normal
                                          : FontWeight.w500, // Reduced from 600
                                      fontFamily: 'Exo2',
                                    ),
                                  ),
                                ),
                                if (!notification.isRead)
                                  Container(
                                    margin: const EdgeInsets.only(
                                        top: 4), // Reduced
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 1), // Reduced
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'NEW',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 7, // Reduced from 8
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
                            padding: const EdgeInsets.only(
                                top: 8), // Reduced from 12
                            child: SizedBox(
                              width: double.infinity,
                              child: Material(
                                borderRadius:
                                    BorderRadius.circular(8), // Reduced
                                elevation: 1, // Reduced
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: colors,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(8), // Reduced
                                    boxShadow: [
                                      BoxShadow(
                                        color: colors[0].withOpacity(0.3),
                                        blurRadius: 4, // Reduced
                                        offset: const Offset(0, 2), // Reduced
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
                                          vertical: 6,
                                          horizontal: 12), // Reduced
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
                                            fontSize: 12, // Reduced from 13
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Exo2',
                                          ),
                                        ),
                                        const SizedBox(width: 4), // Reduced
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                          size: 12, // Reduced from 14
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
      // WRAP with SingleChildScrollView
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16), // Reduced from 24
          child: Container(
            padding: const EdgeInsets.all(20), // Reduced from 24
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFD746C), Color(0xFFFF9068)],
              ),
              borderRadius: BorderRadius.circular(16), // Reduced from 20
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 10, // Reduced from 15
                  offset: const Offset(0, 5), // Reduced from 8
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12), // Reduced from 16
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.exclamationmark_circle_fill,
                    color: Colors.white,
                    size: 32, // Reduced from 40
                  ),
                ),
                const SizedBox(height: 16), // Reduced from 20
                const Text(
                  'Oops!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20, // Reduced from 24
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Exo2',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _refreshNotifications() {
    // This will force the stream to reload
    setState(() {});
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      // WRAP with SingleChildScrollView
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20), // Reduced from 32
          child: Container(
            padding: const EdgeInsets.all(24), // Reduced from 32
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF667EEA).withOpacity(0.1),
                  Color(0xFF764BA2).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20), // Reduced from 24
              border: Border.all(
                color: kPrimaryBlue.withOpacity(0.1),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60, // Reduced from 80
                  height: 60, // Reduced from 80
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimaryBlue, Color(0xFF667EEA)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryBlue.withOpacity(0.3),
                        blurRadius: 10, // Reduced from 15
                        offset: const Offset(0, 5), // Reduced from 8
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.bell_slash,
                    color: Colors.white,
                    size: 28, // Reduced from 35
                  ),
                ),
                const SizedBox(height: 16), // Reduced from 24
                const Text(
                  'All Caught Up! 🎉',
                  style: TextStyle(
                    color: kDarkTextColor,
                    fontSize: 18, // Reduced from 22
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Exo2',
                  ),
                ),
                const SizedBox(height: 8), // Reduced from 12
                const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16), // Reduced from 20
                  child: Text(
                    'No new notifications right now. You\'re all up to date with your messages, reminders, and updates.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kMutedTextColor,
                      fontSize: 13, // Reduced from 14
                      fontFamily: 'Exo2',
                      height: 1.3, // Reduced from 1.4
                    ),
                  ),
                ),
                const SizedBox(height: 16), // Reduced from 20
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6), // Reduced
                  decoration: BoxDecoration(
                    color: kPrimaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8), // Reduced from 12
                  ),
                  child: Text(
                    'Come back later for updates',
                    style: TextStyle(
                      color: kPrimaryBlue,
                      fontSize: 11, // Reduced from 12
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

// How to use it from your home screen:
void showNotificationsWindow(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const NotificationsWindow(),
    barrierColor: Colors.black54,
  );
}
