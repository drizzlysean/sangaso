import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sangaso/src/models/booking_model.dart';
import 'package:sangaso/src/models/notification_model.dart';
import 'package:sangaso/src/services/booking_service.dart';
import 'package:sangaso/src/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore firestore;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc('seeker-1').set({
      'displayName': 'Jane Seeker',
      'email': 'jane@example.com',
      'phoneNumber': '+260977000001',
      'role': 'seeker',
    });
    await firestore.collection('users').doc('provider-1').set({
      'displayName': 'David Provider',
      'tradingName': 'Dave Plumbing',
      'email': 'dave@example.com',
      'phoneNumber': '+260977000002',
      'role': 'provider',
    });
  });

  group('FirebaseBookingService', () {
    test('createBooking writes booking with seeker and provider contact info',
        () async {
      final bookingService = FirebaseBookingService(
        notificationService: FirebaseNotificationService(firestore: firestore),
        firestore: firestore,
      );

      final id = await bookingService.createBooking(
        seekerId: 'seeker-1',
        providerId: 'provider-1',
        serviceType: 'Plumbing',
        scheduledTime: DateTime(2026, 10, 20, 9, 30),
        address: '12 Nakonde Road',
        price: 250,
      );

      final doc = await firestore.collection('bookings').doc(id).get();
      expect(doc.exists, isTrue);

      final booking = BookingModel.fromMap(doc.data()!);
      expect(booking.status, BookingStatus.requested);
      expect(booking.seekerName, 'Jane Seeker');
      expect(booking.seekerPhone, '+260977000001');
      expect(booking.providerName, 'Dave Plumbing');
      expect(booking.providerEmail, 'dave@example.com');
      expect(booking.price, 250);
    });

    test('createBooking notifies the provider of the request', () async {
      final bookingService = FirebaseBookingService(
        notificationService: FirebaseNotificationService(firestore: firestore),
        firestore: firestore,
      );

      final id = await bookingService.createBooking(
        seekerId: 'seeker-1',
        providerId: 'provider-1',
        serviceType: 'Plumbing',
        scheduledTime: DateTime(2026, 10, 20, 9, 30),
        address: '12 Nakonde Road',
        price: 250,
      );

      final notifications = await firestore
          .collection('notifications')
          .where('userId', isEqualTo: 'provider-1')
          .get();
      expect(notifications.docs, hasLength(1));
      final notification =
          NotificationModel.fromMap(notifications.docs.first.data());
      expect(notification.type.name, 'bookingRequest');
      expect(notification.relatedId, id);
      expect(notification.isRead, isFalse);
    });

    test('status transitions write timestamps and notify the seeker',
        () async {
      final bookingService = FirebaseBookingService(
        notificationService: FirebaseNotificationService(firestore: firestore),
        firestore: firestore,
      );

      final id = await bookingService.createBooking(
        seekerId: 'seeker-1',
        providerId: 'provider-1',
        serviceType: 'Plumbing',
        scheduledTime: DateTime(2026, 10, 20, 9, 30),
        address: '12 Nakonde Road',
        price: 250,
      );

      await bookingService.updateBookingStatus(id, BookingStatus.accepted);
      var booking = BookingModel.fromMap(
          (await firestore.collection('bookings').doc(id).get()).data()!);
      expect(booking.status, BookingStatus.accepted);
      expect(booking.acceptedAt, isNotNull);

      await bookingService.updateBookingStatus(id, BookingStatus.inProgress);
      booking = BookingModel.fromMap(
          (await firestore.collection('bookings').doc(id).get()).data()!);
      expect(booking.status, BookingStatus.inProgress);
      expect(booking.startedAt, isNotNull);

      await bookingService.updateBookingStatus(id, BookingStatus.completed);
      booking = BookingModel.fromMap(
          (await firestore.collection('bookings').doc(id).get()).data()!);
      expect(booking.status, BookingStatus.completed);
      expect(booking.completedAt, isNotNull);

      final seekerNotifications = await firestore
          .collection('notifications')
          .where('userId', isEqualTo: 'seeker-1')
          .get();
      final types = seekerNotifications.docs
          .map((d) => NotificationModel.fromMap(d.data()).type)
          .toList();
      expect(
        types,
        containsAll([
          NotificationType.bookingAccepted,
          NotificationType.jobStarted,
          NotificationType.jobCompleted,
        ]),
      );
    });

    test('updateBookingStatus is a no-op for an unknown booking', () async {
      final bookingService = FirebaseBookingService(
        notificationService: FirebaseNotificationService(firestore: firestore),
        firestore: firestore,
      );
      // Must not throw.
      await bookingService.updateBookingStatus(
          'does-not-exist', BookingStatus.accepted);
    });

    test('idempotent retry of an identical open request does not duplicate',
        () async {
      final bookingService = FirebaseBookingService(
        notificationService: FirebaseNotificationService(firestore: firestore),
        firestore: firestore,
      );

      final id1 = await bookingService.createBooking(
        seekerId: 'seeker-1',
        providerId: 'provider-1',
        serviceType: 'Plumbing',
        scheduledTime: DateTime.utc(2026, 10, 20, 7, 30),
        address: '12 Nakonde Road',
        price: 250,
      );
      final id2 = await bookingService.createBooking(
        seekerId: 'seeker-1',
        providerId: 'provider-1',
        serviceType: 'Plumbing',
        scheduledTime: DateTime.utc(2026, 10, 20, 7, 30),
        address: '12 Nakonde Road',
        price: 250,
      );

      expect(id2, id1);
      final bookings = await firestore.collection('bookings').get();
      expect(bookings.docs, hasLength(1));
      // Only the initial provider notification, no retry spam.
      final notifications = await firestore.collection('notifications').get();
      expect(notifications.docs, hasLength(1));
    });

    test('getBookingsForUser returns seeker bookings newest first', () async {
      final bookingService = FirebaseBookingService(
        notificationService: FirebaseNotificationService(firestore: firestore),
        firestore: firestore,
      );

      final firstId = await bookingService.createBooking(
        seekerId: 'seeker-1',
        providerId: 'provider-1',
        serviceType: 'Plumbing',
        scheduledTime: DateTime(2026, 10, 21, 10, 0),
        address: '12 Nakonde Road',
        price: 250,
      );
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final secondId = await bookingService.createBooking(
        seekerId: 'seeker-1',
        providerId: 'provider-1',
        serviceType: 'Electrical',
        scheduledTime: DateTime(2026, 10, 22, 10, 0),
        address: '13 Nakonde Road',
        price: 180,
      );
      await Future<void>.delayed(const Duration(milliseconds: 5));

      final bookings = await bookingService
          .getBookingsForUser('seeker-1', false)
          .first;
      expect(bookings.map((b) => b.id), [secondId, firstId]);
    });
  });
}
