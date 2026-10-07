import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/booking_model.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

abstract class BookingService {
  Future<String> createBooking({
    required String seekerId,
    required String providerId,
    required String serviceType,
    required DateTime scheduledTime,
    required String address,
    required double price,
    String? specialInstructions,
  });

  Stream<List<BookingModel>> getBookingsForUser(String userId, bool isProvider);
  Future<void> updateBookingStatus(String bookingId, BookingStatus status);
}

class FirebaseBookingService implements BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  final NotificationService _notificationService;

  // ✅ Constructor to receive NotificationService
  FirebaseBookingService({required NotificationService notificationService})
    : _notificationService = notificationService;

  @override
  Future<String> createBooking({
    required String seekerId,
    required String providerId,
    required String serviceType,
    required DateTime scheduledTime,
    required String address,
    required double price,
    String? specialInstructions,
  }) async {
    // Fetch seeker and provider details
    final seekerDoc = await _firestore.collection('users').doc(seekerId).get();
    final providerDoc = await _firestore
        .collection('users')
        .doc(providerId)
        .get();

    if (!seekerDoc.exists || !providerDoc.exists) {
      throw Exception('User not found');
    }

    final seekerData = seekerDoc.data()!;
    final providerData = providerDoc.data()!;

    final id = _uuid.v4();
    final booking = BookingModel(
      id: id,
      seekerId: seekerId,
      providerId: providerId,
      serviceType: serviceType,
      scheduledTime: scheduledTime,
      address: address,
      price: price,
      status: BookingStatus.requested,
      createdAt: DateTime.now(),
      // Seeker contact info
      seekerName:
          seekerData['displayName'] ?? seekerData['email']?.split('@')[0],
      seekerPhone: seekerData['phoneNumber'],
      seekerEmail: seekerData['email'],
      // Provider contact info
      providerName:
          providerData['tradingName'] ??
          providerData['displayName'] ??
          providerData['email']?.split('@')[0],
      providerPhone: providerData['phoneNumber'],
      providerEmail: providerData['email'],
      specialInstructions: specialInstructions,
    );

    await _firestore.collection('bookings').doc(id).set(booking.toMap());

    // Notify Provider
    await _notificationService.createNotification(
      userId: providerId,
      title: 'New Booking Request',
      message: 'You have a new request for $serviceType service.',
      type: NotificationType.bookingRequest,
      relatedId: id,
    );

    return id;
  }

  @override
  Stream<List<BookingModel>> getBookingsForUser(
    String userId,
    bool isProvider,
  ) {
    final field = isProvider ? 'providerId' : 'seekerId';
    return _firestore
        .collection('bookings')
        .where(field, isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => BookingModel.fromMap(doc.data()))
              .toList();
          bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return bookings;
        });
  }

  @override
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    final doc = await _firestore.collection('bookings').doc(bookingId).get();
    if (!doc.exists) return;

    final booking = BookingModel.fromMap(doc.data()!);
    final updateData = <String, dynamic>{'status': status.name};

    // Track timestamps for status changes
    switch (status) {
      case BookingStatus.accepted:
        updateData['acceptedAt'] = Timestamp.now();
        break;
      case BookingStatus.inProgress:
        updateData['startedAt'] = Timestamp.now();
        break;
      case BookingStatus.completed:
        updateData['completedAt'] = Timestamp.now();
        break;
      default:
        break;
    }

    await _firestore.collection('bookings').doc(bookingId).update(updateData);

    // Send notifications based on status change
    String? title;
    String? message;
    NotificationType? type;
    String recipientId = booking.seekerId; // Default recipient is seeker

    switch (status) {
      case BookingStatus.accepted:
        title = 'Booking Accepted';
        message =
            '${booking.providerName ?? "Provider"} has accepted your booking.';
        type = NotificationType.bookingAccepted;
        break;
      case BookingStatus.declined:
        title = 'Booking Declined';
        message =
            '${booking.providerName ?? "Provider"} has declined your booking.';
        type = NotificationType.bookingDeclined;
        break;
      case BookingStatus.inProgress:
        title = 'Job Started';
        message = '${booking.providerName ?? "Provider"} has started the job.';
        type = NotificationType.jobStarted;
        break;
      case BookingStatus.completed:
        title = 'Job Completed';
        message = 'Your service has been completed. Please leave a review!';
        type = NotificationType.jobCompleted;
        break;
      case BookingStatus.cancelled:
        // If cancelled by seeker, notify provider
        // If cancelled by provider (unlikely in this flow but possible), notify seeker
        // For now assuming seeker cancels
        recipientId = booking.providerId;
        title = 'Booking Cancelled';
        message =
            '${booking.seekerName ?? "Customer"} has cancelled the booking.';
        type = NotificationType.bookingCancelled;
        break;
      default:
        break;
    }

    if (title != null && type != null) {
      await _notificationService.createNotification(
        userId: recipientId,
        title: title,
        message: message!,
        type: type,
        relatedId: bookingId,
      );
    }
  }

  Future<void> startJob(String bookingId) async {
    await updateBookingStatus(bookingId, BookingStatus.inProgress);
  }

  Future<void> completeJob(String bookingId) async {
    await updateBookingStatus(bookingId, BookingStatus.completed);
  }

  Future<void> cancelBooking(String bookingId) async {
    await updateBookingStatus(bookingId, BookingStatus.cancelled);
  }
}
