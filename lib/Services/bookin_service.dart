import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bookingmodel.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new booking
  Future<void> createBooking(BookingModel booking) async {
    final docRef = _firestore.collection('bookings').doc();
    booking.id = docRef.id; // assign Firestore doc ID
    await docRef.set(booking.toMap());
  }

  /// Fetch bookings for a specific client
  Future<List<BookingModel>> getBookingsByClient(String clientId) async {
    final querySnapshot =
        await _firestore
            .collection('bookings')
            .where('clientId', isEqualTo: clientId)
            .orderBy('dateTime', descending: true)
            .get();

    return querySnapshot.docs
        .map((doc) => BookingModel.fromMap(doc.data()))
        .toList();
  }

  /// Fetch bookings for a specific provider
  Future<List<BookingModel>> getBookingsByProvider(String providerId) async {
    final querySnapshot =
        await _firestore
            .collection('bookings')
            .where('providerId', isEqualTo: providerId)
            .orderBy('dateTime', descending: true)
            .get();

    return querySnapshot.docs
        .map((doc) => BookingModel.fromMap(doc.data()))
        .toList();
  }

  /// Update booking status
  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': status,
    });
  }

  /// Listen to real-time updates for a booking
  Stream<BookingModel> listenBooking(String bookingId) {
    return _firestore
        .collection('bookings')
        .doc(bookingId)
        .snapshots()
        .map((doc) => BookingModel.fromMap(doc.data()!));
  }
}
