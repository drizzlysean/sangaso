import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sangaso/src/services/review_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirebaseReviewService', () {
    test('addReview writes the review and marks it completing a booking',
        () async {
      final firestore = FakeFirebaseFirestore();
      final service = FirebaseReviewService(firestore: firestore);

      await service.addReview(
        bookingId: 'b-7',
        seekerId: 'seeker-1',
        providerId: 'provider-1',
        rating: 4.5,
        comment: 'Quick and tidy work.',
      );

      final docs = await firestore.collection('reviews').get();
      expect(docs.docs, hasLength(1));
      final map = docs.docs.first.data();
      expect(map['bookingId'], 'b-7');
      expect(map['rating'], 4.5);
      expect(map['comment'], 'Quick and tidy work.');
    });

    test('rejects ratings outside the 1-5 range', () async {
      final firestore = FakeFirebaseFirestore();
      final service = FirebaseReviewService(firestore: firestore);

      await expectLater(
        service.addReview(
          bookingId: 'b-8',
          seekerId: 'seeker-1',
          providerId: 'provider-1',
          rating: 9.9,
          comment: 'amazing',
        ),
        throwsA(isA<ArgumentError>()),
      );
      final docs = await firestore.collection('reviews').get();
      expect(docs.docs, isEmpty);
    });

    test('rejects a second review for the same booking', () async {
      final firestore = FakeFirebaseFirestore();
      final service = FirebaseReviewService(firestore: firestore);

      await service.addReview(
        bookingId: 'b-9',
        seekerId: 'seeker-1',
        providerId: 'provider-1',
        rating: 5,
        comment: 'First review.',
      );

      await expectLater(
        service.addReview(
          bookingId: 'b-9',
          seekerId: 'seeker-1',
          providerId: 'provider-1',
          rating: 1,
          comment: 'Double tap retry.',
        ),
        throwsA(isA<Exception>()),
      );
      final docs = await firestore.collection('reviews').get();
      expect(docs.docs, hasLength(1));
    });

    test('getAverageRating averages only that provider reviews', () async {
      final firestore = FakeFirebaseFirestore();
      final service = FirebaseReviewService(firestore: firestore);

      await service.addReview(
        bookingId: 'b-10',
        seekerId: 's-1',
        providerId: 'p-1',
        rating: 5,
        comment: 'a',
      );
      await service.addReview(
        bookingId: 'b-11',
        seekerId: 's-2',
        providerId: 'p-1',
        rating: 3,
        comment: 'b',
      );
      // Another provider, must not affect p-1's average.
      await service.addReview(
        bookingId: 'b-12',
        seekerId: 's-3',
        providerId: 'p-2',
        rating: 1,
        comment: 'c',
      );

      final average = await service.getAverageRating('p-1');
      expect(average, closeTo(4.0, 0.001));
      expect(await service.getAverageRating('p-2'), closeTo(1.0, 0.001));
      expect(await service.getAverageRating('missing'), 0.0);
    });
  });
}
