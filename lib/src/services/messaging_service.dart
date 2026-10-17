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

class SenderNotAllowedException implements Exception {
  final String bookingId;
  final String senderId;
  const SenderNotAllowedException(this.bookingId, this.senderId);

  @override
  String toString() =>
      'Sender is not a participant in this conversation (booking: '
      '$bookingId).';
}

class FirebaseMessagingService implements MessagingService {
  final FirebaseFirestore? _firestoreOverride;
  final _uuid = const Uuid();
  final NotificationService _notificationService;

  // ✅ Constructor to receive NotificationService
  FirebaseMessagingService({
    required NotificationService notificationService,
    FirebaseFirestore? firestore,
  })  : _notificationService = notificationService,
        _firestoreOverride = firestore;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

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
    if (text.trim().isEmpty && imageUrl == null) {
      throw ArgumentError('A message needs text or an image before sending.');
    }

    // Fetch booking first: the sender must be part of this conversation.
    final bookingDoc =
        await _firestore.collection('bookings').doc(bookingId).get();
    if (!bookingDoc.exists) {
      throw StateError('Booking $bookingId does not exist.');
    }
    final data = bookingDoc.data()!;
    final seekerId = data['seekerId'] as String?;
    final providerId = data['providerId'] as String?;
    if (senderId.isEmpty ||
        (senderId != seekerId && senderId != providerId)) {
      throw SenderNotAllowedException(bookingId, senderId);
    }

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

    // Determine recipient (the one who didn't send the message)
    final recipientId = senderId == seekerId ? providerId : seekerId;

    // Get sender name for notification
    final senderDoc = await _firestore.collection('users').doc(senderId).get();
    final senderName = senderDoc.exists
        ? (senderDoc.data()?['displayName'] ?? 'User')
        : 'User';

    if (recipientId != null) {
      await _notificationService.createNotification(
        userId: recipientId,
        title: 'New Message',
        message:
            '$senderName sent you a message: ${text.length > 80 ? '${text.substring(0, 80)}…' : text}',
        type: NotificationType.newMessage,
        relatedId: bookingId,
      );
    }
  }
}
