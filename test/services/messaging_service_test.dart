import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sangaso/src/services/messaging_service.dart';
import 'package:sangaso/src/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore firestore;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc('seeker-1').set({
      'displayName': 'Jane Seeker',
      'role': 'seeker',
    });
    await firestore.collection('users').doc('provider-1').set({
      'displayName': 'Dave Provider',
      'role': 'provider',
    });
    await firestore.collection('bookings').doc('b-1').set({
      'seekerId': 'seeker-1',
      'providerId': 'provider-1',
      'status': 'accepted',
    });
  });

  group('FirebaseMessagingService', () {
    test('sendMessage stamps the sender and notifies the other party',
        () async {
      final messaging = FirebaseMessagingService(
        notificationService: FirebaseNotificationService(firestore: firestore),
        firestore: firestore,
      );

      await messaging.sendMessage(
        bookingId: 'b-1',
        senderId: 'seeker-1',
        text: 'Is 9am still good?',
      );

      final messages = await firestore
          .collection('bookings')
          .doc('b-1')
          .collection('messages')
          .get();
      expect(messages.docs, hasLength(1));
      final data = messages.docs.first.data();
      expect(data['senderId'], 'seeker-1');
      expect(data['bookingId'], 'b-1');
      expect(data['text'], 'Is 9am still good?');
      expect(data['timestamp'], isNotNull);

      // Provider receives exactly one notification, from the seeker.
      final notifications = await firestore
          .collection('notifications')
          .where('userId', isEqualTo: 'provider-1')
          .get();
      expect(notifications.docs, hasLength(1));
      expect(notifications.docs.first.data()['relatedId'], 'b-1');
      expect(
        notifications.docs.first.data()['message'],
        contains('Jane Seeker sent you a message'),
      );
    });

    test('provider sending a message notifies the seeker', () async {
      final messaging = FirebaseMessagingService(
        notificationService: FirebaseNotificationService(firestore: firestore),
        firestore: firestore,
      );

      await messaging.sendMessage(
        bookingId: 'b-1',
        senderId: 'provider-1',
        text: 'On my way.',
      );

      final notifications = await firestore
          .collection('notifications')
          .where('userId', isEqualTo: 'seeker-1')
          .get();
      expect(notifications.docs, hasLength(1));
    });

    test('rejects a sender that is not a participant of the booking',
        () async {
      final messaging = FirebaseMessagingService(
        notificationService: FirebaseNotificationService(firestore: firestore),
        firestore: firestore,
      );

      await firestore.collection('users').doc('stranger-9').set({
        'displayName': 'Stranger',
      });

      await expectLater(
        messaging.sendMessage(
          bookingId: 'b-1',
          senderId: 'stranger-9',
          text: 'hello?',
        ),
        throwsA(isA<SenderNotAllowedException>()),
      );

      final messages = await firestore
          .collection('bookings')
          .doc('b-1')
          .collection('messages')
          .get();
      expect(messages.docs, isEmpty);
    });

    test('rejects empty text without an image', () async {
      final messaging = FirebaseMessagingService(
        notificationService: FirebaseNotificationService(firestore: firestore),
        firestore: firestore,
      );

      await expectLater(
        messaging.sendMessage(
          bookingId: 'b-1',
          senderId: 'seeker-1',
          text: '   ',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects messaging on a booking that does not exist', () async {
      final messaging = FirebaseMessagingService(
        notificationService: FirebaseNotificationService(firestore: firestore),
        firestore: firestore,
      );

      await expectLater(
        messaging.sendMessage(
          bookingId: 'missing',
          senderId: 'seeker-1',
          text: 'hi',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
