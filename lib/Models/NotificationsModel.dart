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

  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
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
      });
      print('✅ Notification created for user: $userId');
    } catch (e) {
      print('❌ Error creating notification: $e');
    }
  }
}
