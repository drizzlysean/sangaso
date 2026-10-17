import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'src/app.dart';
import 'src/services/auth_service.dart';
import 'src/services/booking_service.dart';
import 'src/services/email_verification_service.dart';
import 'src/services/messaging_service.dart';
import 'src/services/notification_service.dart';
import 'src/services/review_service.dart';
import 'src/services/service_service.dart';

const String _kEmulatorFlag = 'SANGASO_USE_EMULATORS';
const String _kEmulatorHost = 'localhost';
const int _kAuthEmulatorPort = 9099;
const int _kFirestoreEmulatorPort = 8080;
const int _kStorageEmulatorPort = 9199;

/// Explicit, OPT-IN Firebase emulator mode.
/// Enabled with `flutter run --dart-define=SANGASO_USE_EMULATORS=true` or by
/// setting the SANGASO_USE_EMULATORS=true environment variable.
/// There is NO automatic production fallback: production/backed Firebase is
/// never touched when this flag is unset.
bool get useEmulators {
  const compileTime = bool.fromEnvironment(_kEmulatorFlag);
  return compileTime || Platform.environment[_kEmulatorFlag] == 'true';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (useEmulators) {
    await FirebaseAuth.instance.useAuthEmulator(_kEmulatorHost, _kAuthEmulatorPort);
    FirebaseFirestore.instance.useFirestoreEmulator(_kEmulatorHost, _kFirestoreEmulatorPort);
    FirebaseStorage.instance.useStorageEmulator(_kEmulatorHost, _kStorageEmulatorPort);
  }

  final authService = FirebaseAuthService();
  final notificationService = FirebaseNotificationService();
  final bookingService = FirebaseBookingService(notificationService: notificationService);
  final messagingService = FirebaseMessagingService(notificationService: notificationService);
  final reviewService = FirebaseReviewService();
  final serviceService = ServiceService();
  final emailVerificationService = FirebaseAuthEmailVerificationService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        Provider<BookingService>.value(value: bookingService),
        Provider<MessagingService>.value(value: messagingService),
        Provider<ReviewService>(create: (_) => reviewService),
        Provider<ServiceService>(create: (_) => serviceService),
        Provider<NotificationService>.value(value: notificationService),
        Provider<EmailVerificationService>.value(value: emailVerificationService),
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
