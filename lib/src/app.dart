import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/router.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'services/booking_service.dart';
import 'services/messaging_service.dart';
import 'services/review_service.dart';
import 'services/service_service.dart';

class SangasoApp extends StatelessWidget {
  final AuthService authService;
  final BookingService bookingService;
  final MessagingService messagingService;
  final ReviewService reviewService;
  final ServiceService serviceService;

  const SangasoApp({
    super.key,
    required this.authService,
    required this.bookingService,
    required this.messagingService,
    required this.reviewService,
    required this.serviceService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<UserModel?>(
          create: (context) => authService.userChanges,
          initialData: null,
        ),
      ],
      child: MaterialApp.router(
        title: 'Sangaso',
        theme: AppTheme.light,
        routerConfig: createRouter(authService),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
