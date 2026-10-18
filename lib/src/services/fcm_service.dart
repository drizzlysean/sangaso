import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Client-side Firebase Cloud Messaging integration.
///
/// Sends nothing from the app: the client only requests permission,
/// registers its token against the authenticated UID, displays foreground
/// messages in-app, and routes tapped messages. Real delivery is the
/// trusted backend's job (Cloud Functions listening on the `notifications`
/// collection). Payloads must stay non-sensitive: type + relatedId only.
class FcmService {
  FcmService({FirebaseMessaging? messaging, FirebaseFirestore? firestore})
      : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  bool _initialized = false;

  /// Android 13+ requires an explicit runtime grant. Must be requested from
  /// a contextual point (post-verification home), never on cold launch.
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<String?> getToken() => _messaging.getToken();

  /// Associates the current token with the user document so the trusted
  /// backend can target this device. Tokens live in a map field on
  /// users/{uid}: { "<token>": <registeredAt> }.
  Future<void> saveToken(String uid) async {
    final token = await getToken();
    if (token == null || token.isEmpty) return;
    _activeUid = uid;
    _lastUid = uid;
    _tokenCache = token;
    await _firestore.collection('users').doc(uid).set(
      {
        'fcmTokens': {token: FieldValue.serverTimestamp()},
      },
      SetOptions(merge: true),
    );
  }

  Future<void> removeToken(String uid) async {
    final token = _tokenCache;
    if (token == null || token.isEmpty) return;
    try {
      await _firestore.collection('users').doc(uid).set(
        {
          'fcmTokens': {token: FieldValue.delete()},
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Token cleanup is best-effort; sign-out must still succeed.
    }
    _tokenCache = null;
    _activeUid = null;
  }

  String? _tokenCache;
  String? _activeUid;
  String? _lastUid;
  String? get lastUid => _lastUid;
  bool _refreshBusy = false;

  /// Wires foreground display, background handling and tap routing.
  /// [onForeground] is invoked for messages received while the app is
  /// visible; the host screen decides how to surface them. [onMessageTapped]
  /// fires when a backgrounded message is opened from the tray.
  void init({
    required void Function(RemoteMessage message) onForeground,
    required void Function(RemoteMessage message) onMessageTapped,
  }) {
    if (_initialized) return;
    _initialized = true;

    // Foreground: stream messages to the host for in-app display.
    FirebaseMessaging.onMessage.listen(onForeground);

    // Background/tap: the app was running in the background and the user
    // opened the message from the tray.
    FirebaseMessaging.onMessageOpenedApp.listen(onMessageTapped);

    // Rotation: platform tokens can be recycled while the app is idle.
    // Re-persist the fresh token for the signed-in user (best-effort,
    // serialized to avoid overlapping writes during rapid rotation).
    _messaging.onTokenRefresh.listen((token) {
      if (token.isEmpty) return;
      _tokenCache = token;
      final uid = _activeUid;
      if (uid == null || _refreshBusy) return;
      _refreshBusy = true;
      _firestore
          .collection('users')
          .doc(uid)
          .set(
            {
              'fcmTokens': {token: FieldValue.serverTimestamp()},
            },
            SetOptions(merge: true),
          )
          .whenComplete(() => _refreshBusy = false);
    });
  }

  /// Cold-start tap: the app was launched from a notification tap, so no
  /// onMessageOpenedApp event fires. Call once after the router is ready.
  Future<void> routeInitialMessage(
    void Function(RemoteMessage message) handler,
  ) async {
    final message = await _messaging.getInitialMessage();
    if (message != null) handler(message);
  }

  Future<void> forgetToken() async {
    try {
      await _messaging.deleteToken();
    } catch (_) {
      // Best-effort cleanup.
    }
    _tokenCache = null;
  }

  /// Caches the latest known token (call after saveToken) so sign-out can
  /// remove exactly that entry even if the platform token rotated.
  void cacheToken(String? token) {
    if (token != null && token.isNotEmpty) _tokenCache = token;
  }
}

/// Top-level background handler. Runs in an isolate with no Flutter binding,
/// so it must stay free of UI work: data-only messages need no local
/// notification here; delivery was performed by the trusted backend.
@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  debugPrint('Sangaso FCM background delivery: ${message.messageId}');
}
