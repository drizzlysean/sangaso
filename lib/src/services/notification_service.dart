import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/notification_model.dart';

// Abstract class/interface that defines the NotificationService contract
abstract class NotificationService {
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  });

  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    String? relatedId,
  });

  Stream<Map<String, dynamic>> getNotifications(String userId);
  Stream<List<NotificationModel>> getUserNotifications(String userId);
  Stream<int> getUnreadCount(String userId);
  Future<void> markAllAsRead(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> checkNotificationData(String userId);
  Future<void> fixMissingIsReadFields(String userId);
  Future<void> markAllAsUnread(String userId);
  Future<void> createTestNotifications(String userId);
}

// Firebase implementation
class FirebaseNotificationService implements NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  @override
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Implementation for push notifications
  }

  @override
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    String? relatedId,
  }) async {
    try {
      final id = _uuid.v4();
      final notification = NotificationModel(
        id: id,
        userId: userId,
        title: title,
        message: message,
        type: type,
        relatedId: relatedId,
        isRead: false,
        createdAt: DateTime.now(),
      );


      await _firestore
          .collection('notifications')
          .doc(id)
          .set(notification.toMap());

    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<Map<String, dynamic>> getNotifications(String userId) {
    return Stream.value({});
  }

  @override
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data()))
              .toList();
        });
  }

  @override
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  @override
  Future<void> checkNotificationData(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();


    for (var doc in snapshot.docs) {
      final data = doc.data();
    }
  }

  @override
  Future<void> fixMissingIsReadFields(String userId) async {

    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();

    final batch = _firestore.batch();
    int fixedCount = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (!data.containsKey('isRead') || data['isRead'] == null) {
        batch.update(doc.reference, {'isRead': false});
        fixedCount++;
      }
    }

    if (fixedCount > 0) {
      await batch.commit();
    } else {
    }
  }

  @override
  Future<void> markAllAsUnread(String userId) async {

    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: true)
        .get();


    if (snapshot.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': false});
      }
      await batch.commit();
    } else {
    }
  }

  @override
  Future<void> createTestNotifications(String userId) async {

    // Create 2 test notifications with isRead: false
    await createNotification(
      userId: userId,
      title: 'Test Notification 1',
      message: 'This is a test notification to check if unread count works',
      type: NotificationType.system,
    );

    await createNotification(
      userId: userId,
      title: 'Test Notification 2',
      message: 'Another test notification with isRead: false',
      type: NotificationType.bookingRequest,
      relatedId: 'test_booking_123',
    );

  }
}
