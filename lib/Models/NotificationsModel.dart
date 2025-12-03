// models/notification_models.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum NotificationType {
  message,
  system,
  reminder,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final String? chatId;
  final String? senderId;
  final String? senderName;
  final String actionText;
  final bool isRead;
  final DateTime time;
  final int messageCount; // ADDED
  final DateTime lastMessageTime; // ADDED

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.chatId,
    this.senderId,
    this.senderName,
    this.actionText = '',
    required this.isRead,
    required this.time,
    this.messageCount = 1, // ADDED with default value
    required this.lastMessageTime, // ADDED
  });

  factory NotificationItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationItem(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: _parseNotificationType(data['type']),
      chatId: data['chatId'],
      senderId: data['senderId'],
      senderName: data['senderName'],
      actionText: data['actionText'] ?? '',
      isRead: data['isRead'] ?? false,
      time: (data['time'] as Timestamp).toDate(),
      messageCount: (data['messageCount'] as num?)?.toInt() ?? 1, // ADDED
      lastMessageTime: data['lastMessageTime'] != null // ADDED
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : (data['time'] as Timestamp).toDate(),
    );
  }

  static NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'NotificationType.message':
      case 'message':
        return NotificationType.message;
      case 'NotificationType.system':
      case 'system':
        return NotificationType.system;
      case 'NotificationType.reminder':
      case 'reminder':
        return NotificationType.reminder;
      default:
        return NotificationType.system;
    }
  }

  // ADDED: Getter for formatted title with message count
  String get formattedTitle {
    if (type == NotificationType.message && messageCount > 1) {
      return title.replaceAllMapped(
        RegExp(r'New message from (.*?)( \(\d+ new\))?'),
        (match) {
          final sender = match[1] ?? '';
          return 'New message from $sender ($messageCount new)';
        },
      );
    }
    return title;
  }

  IconData get icon {
    switch (type) {
      case NotificationType.message:
        return Icons.message;
      case NotificationType.system:
        return Icons.notifications;
      case NotificationType.reminder:
        return Icons.access_time;
      default:
        return Icons.notifications;
    }
  }

  Color get iconColor {
    switch (type) {
      case NotificationType.message:
        return Colors.blue;
      case NotificationType.system:
        return Colors.green;
      case NotificationType.reminder:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class FirebaseService {
  static Stream<List<NotificationItem>> getUserNotifications(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('time', descending: true)
        .snapshots()
        .handleError((error) {
      print('Error fetching notifications: $error');
      return Stream.value([]);
    }).map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationItem.fromFirestore(doc))
          .toList();
    });
  }

  // UPDATED: Mark notification as read AND delete it
  static Future<void> markNotificationAsRead(String notificationId,
      {bool deleteAfterRead = true}) async {
    try {
      if (deleteAfterRead) {
        // Delete the notification when clicked
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(notificationId)
            .delete();
        print('🗑️ Notification deleted: $notificationId');
      } else {
        // Or just mark as read (if you want to keep history)
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(notificationId)
            .update({'isRead': true});
        print('✅ Notification marked as read: $notificationId');
      }
    } catch (e) {
      print('Error handling notification: $e');
    }
  }

  // ADDED: Delete all notifications for a specific chat
  static Future<void> deleteNotificationsForChat(
      String userId, String chatId) async {
    try {
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('chatId', isEqualTo: chatId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      print(
          '🗑️ Deleted ${notifications.docs.length} notifications for chat: $chatId');
    } catch (e) {
      print('Error deleting notifications for chat: $e');
    }
  }

  static Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    String? chatId,
    String? senderId,
    String? senderName,
    String actionText = '',
    int messageCount = 1, // ADDED
    DateTime? lastMessageTime, // ADDED
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type.toString().split('.').last,
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'actionText': actionText,
        'isRead': false,
        'time': FieldValue.serverTimestamp(),
        'messageCount': messageCount, // ADDED
        'lastMessageTime': lastMessageTime != null // ADDED
            ? Timestamp.fromDate(lastMessageTime)
            : FieldValue.serverTimestamp(),
      });
      print('✅ Notification created for user: $userId');
    } catch (e) {
      print('❌ Error creating notification: $e');
    }
  }
}
