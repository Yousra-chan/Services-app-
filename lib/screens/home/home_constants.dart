import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Firebase Services ---
class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Fetch categories from Firestore
  static Stream<List<ServiceCategory>> getCategories() {
    return _firestore
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceCategory.fromFirestore(doc))
            .toList());
  }

  // Alternative search method if arrayContains doesn't work
  static Stream<List<ServiceProvider>> searchProvidersAlternative(
      String query) {
    if (query.isEmpty) {
      return getAllProviders();
    }

    return _firestore
        .collection('providers')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final providers = snapshot.docs
          .map((doc) => ServiceProvider.fromFirestore(doc))
          .toList();

      // Filter locally by name or category
      return providers.where((provider) {
        final nameMatch =
            provider.name.toLowerCase().contains(query.toLowerCase());
        final categoryMatch =
            provider.category.toLowerCase().contains(query.toLowerCase());
        final descriptionMatch =
            provider.description.toLowerCase().contains(query.toLowerCase());

        return nameMatch || categoryMatch || descriptionMatch;
      }).toList();
    });
  }

  static Stream<List<ServiceProvider>> getAllProviders() {
    return _firestore
        .collection('providers')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceProvider.fromFirestore(doc))
          .toList();
    });
  }

  // Fetch popular providers from Firestore
  static Stream<List<ServiceProvider>> getPopularProviders() {
    return _firestore
        .collection('providers')
        .where('isActive', isEqualTo: true)
        .orderBy('rating', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceProvider.fromFirestore(doc))
            .toList());
  }

  // Search providers by name or category
  static Stream<List<ServiceProvider>> searchProviders(String query) {
    if (query.isEmpty) {
      return getPopularProviders();
    }

    return _firestore
        .collection('providers')
        .where('searchKeywords', arrayContains: query.toLowerCase())
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceProvider.fromFirestore(doc))
            .toList());
  }

  // Get user data
  static Stream<DocumentSnapshot> getUserData(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  // NOTIFICATION METHODS - CLEANED AND FIXED
  static Stream<List<NotificationItem>> getUserNotifications(String userId) {
    return _firestore
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

  static Stream<int> getUnreadNotificationCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
      print('✅ Notification marked as read: $notificationId');
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  // Create a new notification
  static Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    String? chatId,
    String? senderId,
    String? senderName,
    String actionText = 'View',
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'time': Timestamp.now(),
        'isRead': false,
        'type': _notificationTypeToString(type),
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'actionText': actionText,
      });
      print('✅ Notification created for user: $userId');
    } catch (e) {
      print('❌ Error creating notification: $e');
    }
  }

  static String _notificationTypeToString(NotificationType type) {
    return type.toString().split('.').last;
  }
}

// --- Data Models ---
class ServiceCategory {
  final String id;
  final String name;
  final IconData icon;
  final String iconCode;
  final bool isActive;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.iconCode,
    this.isActive = true,
  });

  factory ServiceCategory.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Map icon code to IconData
    IconData iconData = _getIconFromCode(data['iconCode'] ?? '');

    return ServiceCategory(
      id: doc.id,
      name: data['name'] ?? '',
      icon: iconData,
      iconCode: data['iconCode'] ?? '',
      isActive: data['isActive'] ?? true,
    );
  }

  static IconData _getIconFromCode(String code) {
    switch (code) {
      case 'pencil':
        return CupertinoIcons.pencil;
      case 'heart_fill':
        return CupertinoIcons.heart_fill;
      case 'car_fill':
        return CupertinoIcons.car_fill;
      case 'sparkles':
        return CupertinoIcons.sparkles;
      case 'house_fill':
        return CupertinoIcons.house_fill;
      case 'wrench_fill':
        return CupertinoIcons.wrench_fill;
      case 'person_2_fill':
        return CupertinoIcons.person_2_fill;
      case 'hammer_fill':
        return CupertinoIcons.hammer_fill;
      case 'scissors':
        return CupertinoIcons.scissors;
      case 'leaf_fill':
        return CupertinoIcons.clear_fill;
      case 'tv_fill':
        return CupertinoIcons.tv_fill;
      case 'phone_fill':
        return CupertinoIcons.phone_fill;
      case 'music_note_2':
        return CupertinoIcons.music_note_2;
      case 'book_fill':
        return CupertinoIcons.book_fill;
      case 'briefcase_fill':
        return CupertinoIcons.briefcase_fill;
      default:
        return CupertinoIcons.circle_fill;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'iconCode': iconCode,
      'isActive': isActive,
    };
  }
}

class ServiceProvider {
  final String id;
  final String name;
  final String category;
  final double rating;
  final int reviews;
  final String distance;
  final String imageUrl;
  final bool isPopular;
  final List<String> searchKeywords;
  final String description;
  final double price;
  final String experience;

  ServiceProvider({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.reviews,
    required this.distance,
    this.imageUrl = '',
    this.isPopular = false,
    this.searchKeywords = const [],
    this.description = '',
    this.price = 0.0,
    this.experience = '',
  });

  factory ServiceProvider.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ServiceProvider(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviews: data['reviews'] ?? 0,
      distance: data['distance'] ?? '0 km',
      imageUrl: data['imageUrl'] ?? '',
      isPopular: data['isPopular'] ?? false,
      searchKeywords: List<String>.from(data['searchKeywords'] ?? []),
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      experience: data['experience'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'rating': rating,
      'reviews': reviews,
      'distance': distance,
      'imageUrl': imageUrl,
      'isPopular': isPopular,
      'searchKeywords': searchKeywords,
      'description': description,
      'price': price,
      'experience': experience,
    };
  }
}

// COMPLETE NotificationItem class
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
      case 'NotificationType.booking':
      case 'booking':
        return NotificationType.booking;
      case 'NotificationType.payment':
      case 'payment':
        return NotificationType.payment;
      case 'NotificationType.reminder':
      case 'reminder':
        return NotificationType.reminder;
      case 'NotificationType.promotional':
      case 'promotional':
        return NotificationType.promotional;
      case 'NotificationType.rating':
      case 'rating':
        return NotificationType.rating;
      case 'NotificationType.health':
      case 'health':
        return NotificationType.health;
      default:
        return NotificationType.message;
    }
  }

  IconData get icon {
    switch (type) {
      case NotificationType.booking:
        return CupertinoIcons.calendar;
      case NotificationType.payment:
        return CupertinoIcons.money_dollar_circle_fill;
      case NotificationType.reminder:
        return CupertinoIcons.clock_fill;
      case NotificationType.promotional:
        return CupertinoIcons.sparkles;
      case NotificationType.rating:
        return CupertinoIcons.star_fill;
      case NotificationType.health:
        return CupertinoIcons.heart_fill;
      case NotificationType.message:
      default:
        return CupertinoIcons.chat_bubble_fill;
    }
  }

  Color get iconColor {
    switch (type) {
      case NotificationType.booking:
        return Colors.green;
      case NotificationType.payment:
        return Colors.green;
      case NotificationType.reminder:
        return Colors.orange;
      case NotificationType.promotional:
        return Colors.purple;
      case NotificationType.rating:
        return kRatingYellow;
      case NotificationType.health:
        return Colors.red;
      case NotificationType.message:
      default:
        return kPrimaryBlue;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'time': Timestamp.fromDate(time),
      'isRead': isRead,
      'type': _notificationTypeToString(type),
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'actionText': actionText,
    };
  }

  static String _notificationTypeToString(NotificationType type) {
    return type.toString().split('.').last;
  }
}

// Fixed NotificationType enum
enum NotificationType {
  message,
  booking,
  payment,
  reminder,
  promotional,
  rating,
  health,
}

// --- Global Constants ---
// Colors
const Color kPrimaryBlue = Color.fromARGB(255, 12, 94, 153);
const Color kLightBackgroundColor = Color.fromARGB(255, 248, 249, 255);
const Color kCardBackgroundColor = Colors.white;
const Color kDarkTextColor = Color.fromARGB(255, 50, 50, 50);
const Color kMutedTextColor = Color.fromARGB(255, 150, 150, 150);
const Color kSoftShadowColor = Color.fromARGB(50, 87, 101, 240);
const Color kRatingYellow = Color.fromARGB(255, 255, 193, 7);
const Color kSuccessGreen = Color.fromARGB(255, 76, 175, 80);
const Color kWarningOrange = Color.fromARGB(255, 255, 152, 0);
const Color kErrorRed = Color.fromARGB(255, 244, 67, 54);
const Color kUnreadNotificationColor = Color.fromARGB(255, 236, 245, 255);

// Text Styles
const TextStyle kHeaderTextStyle = TextStyle(
  color: Colors.white,
  fontSize: 24,
  fontWeight: FontWeight.w800,
  fontFamily: 'Exo2',
);

const TextStyle kSubHeaderTextStyle = TextStyle(
  color: Colors.white70,
  fontSize: 16,
  fontFamily: 'Exo2',
);

const TextStyle kSectionTitleTextStyle = TextStyle(
  color: kDarkTextColor,
  fontSize: 20,
  fontWeight: FontWeight.w700,
  fontFamily: 'Exo2',
);

const TextStyle kCardTitleTextStyle = TextStyle(
  color: kDarkTextColor,
  fontSize: 17,
  fontWeight: FontWeight.w700,
  fontFamily: 'Exo2',
);

const TextStyle kCardSubtitleTextStyle = TextStyle(
  color: kMutedTextColor,
  fontSize: 13,
  fontFamily: 'Exo2',
);

const TextStyle kBodyTextStyle = TextStyle(
  color: kDarkTextColor,
  fontSize: 14,
  fontFamily: 'Exo2',
);

const TextStyle kCaptionTextStyle = TextStyle(
  color: kMutedTextColor,
  fontSize: 12,
  fontFamily: 'Exo2',
);

// Default categories (fallback)
final List<ServiceCategory> defaultCategories = [
  ServiceCategory(
    id: '1',
    name: "Teaching",
    icon: CupertinoIcons.pencil,
    iconCode: 'pencil',
  ),
  ServiceCategory(
    id: '2',
    name: "Health",
    icon: CupertinoIcons.heart_fill,
    iconCode: 'heart_fill',
  ),
  ServiceCategory(
    id: '3',
    name: "Mechanic",
    icon: CupertinoIcons.car_fill,
    iconCode: 'car_fill',
  ),
  ServiceCategory(
    id: '4',
    name: "Clean",
    icon: CupertinoIcons.sparkles,
    iconCode: 'sparkles',
  ),
  ServiceCategory(
    id: '5',
    name: "Plumbing",
    icon: CupertinoIcons.wrench_fill,
    iconCode: 'wrench_fill',
  ),
  ServiceCategory(
    id: '6',
    name: "Electrical",
    icon: CupertinoIcons.bolt_fill,
    iconCode: 'bolt_fill',
  ),
  ServiceCategory(
    id: '7',
    name: "Beauty",
    icon: CupertinoIcons.scissors,
    iconCode: 'scissors',
  ),
  ServiceCategory(
    id: '8',
    name: "Gardening",
    icon: CupertinoIcons.clear_fill,
    iconCode: 'leaf_fill',
  ),
];

// Default providers (fallback)
final List<ServiceProvider> defaultProviders = [
  ServiceProvider(
    id: '1',
    name: "Dr. Ahmed Hassan",
    category: "Pediatrician",
    rating: 4.9,
    reviews: 540,
    distance: "1.2 km",
    imageUrl: "",
    isPopular: true,
    description: "Specialized in child healthcare with 10 years of experience",
    price: 50.0,
    experience: "10 years",
  ),
  ServiceProvider(
    id: '2',
    name: "Khaled Electrics",
    category: "Electrician",
    rating: 4.7,
    reviews: 210,
    distance: "3.5 km",
    imageUrl: "",
    isPopular: true,
    description: "Professional electrical services for homes and offices",
    price: 35.0,
    experience: "8 years",
  ),
  ServiceProvider(
    id: '3',
    name: "Sara Plumbing",
    category: "Plumber",
    rating: 4.5,
    reviews: 155,
    distance: "0.8 km",
    imageUrl: "",
    isPopular: true,
    description: "Emergency plumbing services available 24/7",
    price: 40.0,
    experience: "6 years",
  ),
  ServiceProvider(
    id: '4',
    name: "Tutor Omar",
    category: "Math Tutor",
    rating: 5.0,
    reviews: 98,
    distance: "5.1 km",
    imageUrl: "",
    isPopular: true,
    description: "Mathematics tutoring for all levels",
    price: 25.0,
    experience: "5 years",
  ),
];

// App Constants
const double kDefaultPadding = 16.0;
const double kDefaultBorderRadius = 15.0;
const double kCardElevation = 4.0;
const Duration kAnimationDuration = Duration(milliseconds: 300);
