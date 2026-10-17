import 'package:firebase_auth/firebase_auth.dart';

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
  FirebaseAuthEmailVerificationService({FirebaseAuth? auth}) : _authOverride = auth;

  final FirebaseAuth? _authOverride;

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
    await _auth.currentUser?.sendEmailVerification();
  }
}
