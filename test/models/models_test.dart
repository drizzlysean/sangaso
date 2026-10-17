import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sangaso/src/models/booking_model.dart';
import 'package:sangaso/src/models/message_model.dart';
import 'package:sangaso/src/models/notification_model.dart';
import 'package:sangaso/src/models/review_model.dart';
import 'package:sangaso/src/models/service_model.dart';
import 'package:sangaso/src/models/user_model.dart';

const int _msStory = 1748736000000; // fixed, TZ-independent

Map<String, dynamic> bookingBase() => {
      'id': 'b1',
      'seekerId': 's1',
      'providerId': 'p1',
      'serviceType': 'Cleaning',
      'scheduledTime': Timestamp.fromDate(DateTime(2026, 3, 1)),
      'address': '12 Test Street',
      'price': 150.0,
      'status': 'requested',
      'createdAt': Timestamp.fromDate(DateTime(2026, 2, 1)),
    };

void main() {
  group('BookingModel.fromMap', () {
    test('round-trips via toMap/fromMap', () {
      final model = BookingModel.fromMap(bookingBase());
      final restored = BookingModel.fromMap(model.toMap());
      expect(restored.id, model.id);
      expect(restored.price, model.price);
      expect(restored.status, model.status);
      expect(restored.scheduledTime, model.scheduledTime);
    });

    test('accepts ISO-8601 strings', () {
      final m = BookingModel.fromMap(bookingBase()
        ..['scheduledTime'] = '2026-03-01T08:00:00.000Z'
        ..['createdAt'] = '2026-02-01T08:00:00.000Z');
      expect(m.scheduledTime.year, 2026);
    });

    test('accepts integer milliseconds', () {
      final m = BookingModel.fromMap(bookingBase()
        ..['scheduledTime'] = _msStory
        ..['createdAt'] = _msStory);
      expect(m.scheduledTime.toUtc().millisecondsSinceEpoch, _msStory);
    });

    test('keeps optional status-time fields null when absent and parses mixed types', () {
      final m = BookingModel.fromMap(bookingBase()
        ..['acceptedAt'] = Timestamp.fromDate(DateTime(2026, 2, 2))
        ..['startedAt'] = '2026-02-02T09:00:00.000Z'
        ..['completedAt'] = _msStory);
      expect(m.acceptedAt, isNotNull);
      expect(m.startedAt!.year, 2026);
      expect(m.completedAt!.toUtc().millisecondsSinceEpoch, _msStory);
    });

    test('accepts raw DateTime values', () {
      final m = BookingModel.fromMap(bookingBase()
        ..['scheduledTime'] = DateTime(2026, 3, 1)
        ..['createdAt'] = DateTime(2026, 2, 1));
      expect(m.scheduledTime, DateTime(2026, 3, 1));
    });
  });

  group('ServiceModel.fromMap', () {
    Map<String, dynamic> serviceBase() => {
          'id': 'sv1',
          'providerId': 'p1',
          'name': 'Deep clean',
          'description': 'Full apartment clean',
          'category': 'Cleaning',
          'price': 250,
          'imageUrls': const <String>[],
          'isActive': true,
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
          'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 2)),
        };

    test('accepts Timestamp, ISO string and int-ms dates', () {
      expect(
          ServiceModel.fromMap(serviceBase()).createdAt.millisecondsSinceEpoch,
          DateTime(2026, 1, 1).millisecondsSinceEpoch);
      expect(
          ServiceModel.fromMap(serviceBase()
                ..['createdAt'] = '2026-01-01T00:00:00.000Z')
              .createdAt
              .toUtc()
              .year,
          2026);
      expect(
          ServiceModel.fromMap(serviceBase()..['createdAt'] = _msStory)
              .createdAt
              .toUtc()
              .millisecondsSinceEpoch,
          _msStory);
    });

    test('fails loudly on missing createdAt', () {
      final missing = serviceBase();
      missing.remove('createdAt');
      expect(
        () => ServiceModel.fromMap(missing),
        throwsA(isA<FormatException>().having(
            (e) => e.message, 'message', contains('createdAt'))),
      );
    });
  });

  group('UserModel.fromMap', () {
    test('parses ISO strings (legacy) and Timestamps without crashing', () {
      expect(
          UserModel.fromMap({
            'id': 'u1',
            'email': 'a@b.c',
            'role': 'provider',
            'createdAt': '2026-01-01T00:00:00.000Z',
          }).createdAt!.toUtc().year,
          2026);
      expect(
          UserModel.fromMap({
            'id': 'u1',
            'email': 'a@b.c',
            'role': 'seeker',
            'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
          }).createdAt,
          DateTime(2026, 1, 1));
    });

    test('fails loudly on malformed non-null dates', () {
      expect(
        () => UserModel.fromMap({
          'id': 'u1',
          'email': 'a@b.c',
          'role': 'seeker',
          'createdAt': 'not-a-date',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('ReviewModel / NotificationModel / MessageModel.fromMap', () {
    test('parses and round-trips dates', () {
      final review = ReviewModel.fromMap({
        'id': 'r1',
        'bookingId': 'b1',
        'seekerId': 's1',
        'providerId': 'p1',
        'rating': 4.5,
        'comment': 'Great work',
        'createdAt': '2026-01-01T00:00:00.000Z',
      });
      expect(review.createdAt.toUtc().year, 2026);

      final notification = NotificationModel.fromMap({
        'id': 'n1',
        'userId': 'u1',
        'title': 'Hello',
        'message': 'New booking',
        'type': 'bookingRequest',
        'createdAt': _msStory,
      });
      expect(notification.createdAt.toUtc().millisecondsSinceEpoch, _msStory);

      final message = MessageModel.fromMap({
        'id': 'm1',
        'bookingId': 'b1',
        'senderId': 's1',
        'text': 'Hi',
        'timestamp': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });
      expect(message.timestamp, DateTime(2026, 1, 1));
    });
  });
}
