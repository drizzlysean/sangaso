import 'dart:async';

import 'package:sangaso/src/models/notification_model.dart';

import '../services/notification_service.dart';

// ... Keep all your existing MockAuthService, MockBookingService, etc. ...

class MockNotificationService implements NotificationService {
  final List<NotificationModel> _notifications = [];
  final StreamController<List<NotificationModel>> _controller =
      StreamController<List<NotificationModel>>.broadcast();

  MockNotificationService() {
    // Add some mock notifications for testing
    _notifications.addAll([
      NotificationModel(
        id: 'notification_1',
        userId: 'mock_user_1',
        title: 'New Booking Request',
        message: 'John Doe has requested your plumbing service',
        type: NotificationType.bookingRequest,
        relatedId: 'mock_booking_1',
        isRead: false, // Changed to false for testing
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NotificationModel(
        id: 'notification_2',
        userId: 'mock_user_1',
        title: 'Booking Accepted',
        message: 'Your booking request has been accepted',
        type: NotificationType.bookingAccepted,
        relatedId: 'mock_booking_2',
        isRead: false, // Changed to false for testing
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      NotificationModel(
        id: 'notification_3',
        userId: 'mock_user_1',
        title: 'Job Completed',
        message: 'Your plumbing job has been marked as completed',
        type: NotificationType.jobCompleted,
        relatedId: 'mock_booking_3',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);
    _controller.add(List.from(_notifications));
  }

  @override
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock implementation
  }

  @override
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    String? relatedId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final notification = NotificationModel(
      id: 'notification_${_notifications.length + 1}',
      userId: userId,
      title: title,
      message: message,
      type: type,
      relatedId: relatedId,
      isRead: false, // Always false for new notifications
      createdAt: DateTime.now(),
    );
    _notifications.add(notification);
    _controller.add(List.from(_notifications));
  }

  @override
  Stream<Map<String, dynamic>> getNotifications(String userId) {
    return Stream.value({});
  }

  @override
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _controller.stream.map(
      (notifications) =>
          notifications.where((n) => n.userId == userId).toList(),
    );
  }

  @override
  Stream<int> getUnreadCount(String userId) {
    return _controller.stream.map((notifications) {
      return notifications.where((n) => n.userId == userId && !n.isRead).length;
    });
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    for (var i = 0; i < _notifications.length; i++) {
      if (_notifications[i].userId == userId) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    _controller.add(List.from(_notifications));
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _controller.add(List.from(_notifications));
    }
  }

  @override
  Future<void> checkNotificationData(String userId) async {
    for (var notification in _notifications) {
      if (notification.userId == userId) {
      }
    }
  }

  @override
  Future<void> fixMissingIsReadFields(String userId) async {
    // In mock, we don't need to fix anything since we control the data
  }

  // ADD THESE TWO NEW METHODS:
  @override
  Future<void> markAllAsUnread(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    for (var i = 0; i < _notifications.length; i++) {
      if (_notifications[i].userId == userId && _notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: false);
      }
    }

    _controller.add(List.from(_notifications));
  }

  @override
  Future<void> createTestNotifications(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Create 2 test notifications
    await createNotification(
      userId: userId,
      title: 'Mock Test Notification 1',
      message: 'This is a mock test notification created for testing',
      type: NotificationType.system,
    );

    await createNotification(
      userId: userId,
      title: 'Mock Test Notification 2',
      message: 'Another mock test notification with booking request',
      type: NotificationType.bookingRequest,
      relatedId: 'mock_test_booking_123',
    );

  }
}
