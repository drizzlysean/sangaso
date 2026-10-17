import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:sangaso/src/app.dart';
import 'package:sangaso/src/models/booking_model.dart';
import 'package:sangaso/src/models/message_model.dart';
import 'package:sangaso/src/models/review_model.dart';
import 'package:sangaso/src/services/booking_service.dart';
import 'package:sangaso/src/services/messaging_service.dart';
import 'package:sangaso/src/services/review_service.dart';
import 'package:sangaso/src/services/service_service.dart';

import 'fakes/fake_auth_service.dart';

class NoopBookingService implements BookingService {
  @override
  Future<String> createBooking({
    required String seekerId,
    required String providerId,
    required String serviceType,
    required DateTime scheduledTime,
    required String address,
    required double price,
    String? specialInstructions,
  }) =>
      throw UnimplementedError('not used by the splash smoke test');

  @override
  Stream<List<BookingModel>> getBookingsForUser(String userId, bool isProvider) =>
      const Stream.empty();

  @override
  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {}
}

class NoopMessagingService implements MessagingService {
  @override
  Stream<List<MessageModel>> getMessages(String bookingId) => const Stream.empty();

  @override
  Future<void> sendMessage({
    required String bookingId,
    required String senderId,
    required String text,
    String? imageUrl,
  }) async {}
}

class NoopReviewService implements ReviewService {
  @override
  Future<void> addReview({
    required String bookingId,
    required String seekerId,
    required String providerId,
    required double rating,
    required String comment,
  }) async {}

  @override
  Stream<List<ReviewModel>> getReviewsForProvider(String providerId) =>
      const Stream.empty();

  @override
  Future<double> getAverageRating(String providerId) => Future.value(0);
}

void main() {
  final auth = FakeAuthService(); // starts uninitialized? -> see below
  // FakeAuthService defaults to isInitialized=true with a null user, so the
  // router redirects '/' -> '/welcome'.

  testWidgets('app shell boots and shows welcome when signed out', (tester) async {
    final services = ServiceService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [Provider<ServiceService>.value(value: services)],
        child: SangasoApp(
          authService: auth,
          bookingService: NoopBookingService(),
          messagingService: NoopMessagingService(),
          reviewService: NoopReviewService(),
          serviceService: services,
        ),
      ),
    );
    // Router redirect: user == null -> '/welcome'
    await tester.pumpAndSettle();

    expect(find.text('SANGASO'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });
}
