import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/router.dart';
import 'core/constants/app_colors.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'services/booking_service.dart';
import 'services/fcm_service.dart';
import 'services/messaging_service.dart';
import 'services/review_service.dart';
import 'services/service_service.dart';

final GlobalKey<ScaffoldMessengerState> sangasoMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class SangasoApp extends StatefulWidget {
  final AuthService authService;
  final BookingService bookingService;
  final MessagingService messagingService;
  final ReviewService reviewService;
  final ServiceService serviceService;

  /// Optional FCM integration. Only provided by the production entrypoint;
  /// widget tests construct the app without it so no platform channels or
  /// permission prompts are touched during tests.
  final FcmService? fcmService;

  const SangasoApp({
    super.key,
    required this.authService,
    required this.bookingService,
    required this.messagingService,
    required this.reviewService,
    required this.serviceService,
    this.fcmService,
  });

  @override
  State<SangasoApp> createState() => _SangasoAppState();
}

class _SangasoAppState extends State<SangasoApp> {
  late final FcmService? _fcm = widget.fcmService;
  late final GoRouter _router = createRouter(widget.authService);
  StreamSubscription<UserModel?>? _authSub;
  bool _fcmSyncBusy = false;

  @override
  void initState() {
    super.initState();
    final fcm = _fcm;
    if (fcm != null) {
      fcm.init(
        onForeground: _showForegroundMessage,
        onMessageTapped: _routeForMessage,
      );
      fcm.routeInitialMessage(_routeForMessage);
      _authSub = widget.authService.userChanges.listen((user) {
        _syncFcmForUser(user);
      });
    }
  }

  /// Permission request and token lifecycle follow the signed-in, verified
  /// user. Sign-out removes this device's token so the backend stops
  /// targeting it. All best-effort: failures never block auth flows.
  Future<void> _syncFcmForUser(UserModel? user) async {
    final fcm = _fcm;
    if (fcm == null || _fcmSyncBusy) return;
    _fcmSyncBusy = true;
    try {
      if (user == null) {
        await fcm.removeToken(fcm.lastUid ?? '');
      } else if (user.isVerified) {
        final granted = await fcm.requestPermission();
        if (granted) await fcm.saveToken(user.id);
      }
    } catch (_) {
      // Non-fatal: notification delivery stays a progressive enhancement.
    } finally {
      _fcmSyncBusy = false;
    }
  }


  /// Foreground display: brief, non-intrusive snackbar with the title and
  /// body. Deep navigation stays behind the tap-routing path.
  void _showForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ?? 'Sangaso update';
    final body = message.notification?.body ?? '';
    sangasoMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(body.isEmpty ? title : '$title: $body'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  /// Tap routing: FCM payloads carry `type` and `relatedId` only. Related
  /// to NotificationType names: newMessage -> chat, everything else that
  /// has a relatedId -> booking details. Unknown/missing ids fall back to
  /// the shell home so a malformed payload can never dead-end the app.
  void _routeForMessage(RemoteMessage message) {
    final type = (message.data['type'] as String?)?.toLowerCase() ?? '';
    final relatedId = message.data['relatedId'] as String?;
    if (relatedId == null || relatedId.isEmpty) {
      _router.go('/home');
      return;
    }
    if (type.contains('message')) {
      _router.push('/chat/$relatedId');
    } else {
      _router.push('/booking/$relatedId');
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<UserModel?>(
          create: (context) => widget.authService.userChanges,
          initialData: null,
        ),
      ],
      child: MaterialApp.router(
        title: 'Sangaso',
        theme: AppTheme.light,
        routerConfig: _router,
        scaffoldMessengerKey: sangasoMessengerKey,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
