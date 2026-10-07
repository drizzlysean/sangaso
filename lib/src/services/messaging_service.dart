import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/message_model.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

abstract class MessagingService {
  Stream<List<MessageModel>> getMessages(String bookingId);
  Future<void> sendMessage({
    required String bookingId,
    required String senderId,
    required String text,
    String? imageUrl,
  });
}

class FirebaseMessagingService implements MessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  final NotificationService _notificationService;

  // ✅ Constructor to receive NotificationService
  FirebaseMessagingService({required NotificationService notificationService})
    : _notificationService = notificationService;

  @override
  Stream<List<MessageModel>> getMessages(String bookingId) {
    return _firestore
        .collection('bookings')
        .doc(bookingId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data()))
              .toList(),
        );
  }

  @override
  Future<void> sendMessage({
    required String bookingId,
    required String senderId,
    required String text,
    String? imageUrl,
  }) async {
    final id = _uuid.v4();
    final message = MessageModel(
      id: id,
      bookingId: bookingId,
      senderId: senderId,
      text: text,
      imageUrl: imageUrl,
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection('bookings')
        .doc(bookingId)
        .collection('messages')
        .doc(id)
        .set(message.toMap());

    // Fetch booking to determine recipient
    try {
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();
      if (bookingDoc.exists) {
        final data = bookingDoc.data()!;
        final seekerId = data['seekerId'] as String;
        final providerId = data['providerId'] as String;

        // Determine recipient (the one who didn't send the message)
        final recipientId = senderId == seekerId ? providerId : seekerId;

        // Get sender name for notification
        final senderDoc = await _firestore
            .collection('users')
            .doc(senderId)
            .get();
        final senderName = senderDoc.exists
            ? (senderDoc.data()?['displayName'] ?? 'User')
            : 'User';

        await _notificationService.createNotification(
          userId: recipientId,
          title: 'New Message',
          message: '$senderName sent you a message: $text',
          type: NotificationType.newMessage,
          relatedId: bookingId,
        );
      }
    } catch (e) {
    }
  }
}
