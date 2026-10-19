import 'package:firebase_auth/firebase_auth.dart';

import 'auth_email_service.dart';

/// Seam for email-verification behaviour so screens (and widget tests) never
/// need to touch FirebaseAuth.instance directly. Tests inject a fake; the
/// production implementation is wired in main.dart.
abstract class EmailVerificationService {
  bool get isSignedIn;
  String? get currentUserEmail;
  bool get currentEmailVerified;

  /// Reloads the current user's profile from the server and returns
  /// whether their email is verified now.
  Future<bool> reloadAndCheckVerified();

  Future<void> sendVerificationEmail();
}

class FirebaseAuthEmailVerificationService implements EmailVerificationService {
  FirebaseAuthEmailVerificationService({
    FirebaseAuth? auth,
    AuthEmailService? authEmailService,
  })  : _authOverride = auth,
        _authEmailService = authEmailService;

  final FirebaseAuth? _authOverride;

  /// Optional branded-email client. When the build enables the custom
  /// transport, verification emails go through the website's branded API;
  /// otherwise Firebase's default sender stays in charge.
  final AuthEmailService? _authEmailService;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  @override
  bool get isSignedIn => _auth.currentUser != null;

  @override
  String? get currentUserEmail => _auth.currentUser?.email;

  @override
  bool get currentEmailVerified => _auth.currentUser?.emailVerified ?? false;

  @override
  Future<bool> reloadAndCheckVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return user.emailVerified;
  }

  @override
  Future<void> sendVerificationEmail() async {
    final custom = _authEmailService;
    if (custom != null && custom.customEnabled) {
      // Branded transport: exactly one request, and NO automatic fallback to
      // Firebase afterwards (a silent fallback could send a second email).
      final result = await custom.requestVerificationEmail();
      switch (result.outcome) {
        case AuthEmailOutcome.sent:
        case AuthEmailOutcome.alreadyVerified:
          return;
        case AuthEmailOutcome.disabled:
          break; // unreachable while customEnabled is true
        default:
          throw AuthEmailException(result);
      }
    }
    await _auth.currentUser?.sendEmailVerification();
  }
}
