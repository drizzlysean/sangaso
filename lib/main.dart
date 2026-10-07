import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'src/app.dart';
import 'src/services/auth_service.dart';
import 'src/services/booking_service.dart';
import 'src/services/messaging_service.dart';
import 'src/services/notification_service.dart';
import 'src/services/review_service.dart';
import 'src/services/service_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final authService = FirebaseAuthService();
  final notificationService = FirebaseNotificationService();
  final bookingService = FirebaseBookingService(notificationService: notificationService);
  final messagingService = FirebaseMessagingService(notificationService: notificationService);
  final reviewService = FirebaseReviewService();
  final serviceService = ServiceService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        Provider<BookingService>.value(value: bookingService),
        Provider<MessagingService>.value(value: messagingService),
        Provider<ReviewService>(create: (_) => reviewService),
        Provider<ServiceService>(create: (_) => serviceService),
        Provider<NotificationService>.value(value: notificationService),
      ],
      child: SangasoApp(
        authService: authService,
        bookingService: bookingService,
        messagingService: messagingService,
        reviewService: reviewService,
        serviceService: serviceService,
      ),
    ),
  );
}
