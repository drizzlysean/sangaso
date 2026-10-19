import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

// USE RELATIVE IMPORT INSTEAD OF PACKAGE IMPORT:
import '../models/user_model.dart'; // This should work since both are in src folder
import 'auth_email_service.dart';

/// Outcome of a Google sign-in attempt.
enum GoogleSignInOutcome {
  /// An existing account was signed in (returning user — no consent gate).
  signedIn,

  /// A brand-new Google account needs explicit consent before the
  /// profile record is created. Call [AuthService.completeGoogleConsent]
  /// after the user accepts the Terms and Privacy Notice.
  consentRequired,
}

abstract class AuthService extends ChangeNotifier {
  Stream<UserModel?> get userChanges;
  UserModel? get currentUserModel;
  bool get isInitialized;

  Future<void> signIn(String email, String password);
  Future<GoogleSignInOutcome> signInWithGoogle();
  Future<void> completeGoogleConsent();
  Future<void> signUp({
    required String email,
    required String password,
    required UserRole role,
    String? name,
    bool acceptedConsent = false,
  });
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<void> updateUser(UserModel user);
  Future<UserModel?> getCurrentUserModel();
  Future<UserModel?> fetchUserByEmail(String email); // ADD THIS METHOD
}

class FirebaseAuthService extends AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? _cachedUser;
  bool _isInitialized = false;
  String? _previousUserId;

  /// Optional branded-email client (website `api/auth-mail.php`). Present in
  /// every build, but only ACTIVE when the build enables the custom
  /// transport; otherwise Firebase's default sender stays in charge.
  final AuthEmailService? _authEmailService;

  FirebaseAuthService({AuthEmailService? authEmailService})
      : _authEmailService = authEmailService {
    // Safety net: Force initialization after 5 seconds if stream doesn't emit
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isInitialized) {
        _isInitialized = true;
        notifyListeners();
      }
    });

    _auth.authStateChanges().listen((User? user) async {
      final String? currentUserId = user?.uid;

      // Always update when user changes
      if (_previousUserId != currentUserId || !_isInitialized) {
        _previousUserId = currentUserId;

        if (user == null) {
          _cachedUser = null;
        } else {
          _cachedUser = await getCurrentUserModel();
        }

        _isInitialized = true;

        // Always notify listeners to ensure UI updates immediately
        notifyListeners();
      }
    });
  }

  @override
  bool get isInitialized => _isInitialized;

  @override
  Stream<UserModel?> get userChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) {
        return null;
      }
      // We might already have it cached from the listener, but to be safe/consistent with the stream:
      return await getCurrentUserModel();
    });
  }

  @override
  UserModel? get currentUserModel => _cachedUser;

  @override
  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          return UserModel.fromMap(data);
        }
      }
    } catch (e) {
      if (kDebugMode) {
      }
    }
    return null;
  }

  // ADD THIS METHOD: Fetch user by email
  @override
  Future<UserModel?> fetchUserByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return UserModel.fromMap(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
      }
      return null;
    }
  }

  @override
  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    // Populate the cache synchronously with the sign-in flow instead of
    // relying solely on the authStateChanges() listener, which fires on
    // its own async timeline and can race with callers that read
    // currentUserModel immediately after this call resolves.
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      _previousUserId = uid;
      _cachedUser = await getCurrentUserModel();
      _isInitialized = true;
      notifyListeners();
    }
  }

  @override
  Future<GoogleSignInOutcome> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      // User cancelled the account picker: not an error.
      return GoogleSignInOutcome.signedIn;
    }

    // Returning user? Check the users collection by email BEFORE any
    // account creation. Returning users must never hit a consent gate.
    final existing = await fetchUserByEmail(googleUser.email);

    if (existing != null) {
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      final uid = cred.user?.uid;
      if (uid == null) return GoogleSignInOutcome.signedIn;
      _previousUserId = uid;
      _cachedUser = await getCurrentUserModel();
      _isInitialized = true;
      notifyListeners();
      return GoogleSignInOutcome.signedIn;
    }

    // New Google account: keep the picker result pending. No Firebase
    // account is created and no profile record is written until the
    // caller confirms consent via completeGoogleConsent().
    _pendingGoogleUser = googleUser;
    return GoogleSignInOutcome.consentRequired;
  }

  GoogleSignInAccount? _pendingGoogleUser;

  @override
  Future<void> completeGoogleConsent() async {
    final googleUser = _pendingGoogleUser;
    if (googleUser == null) {
      throw StateError('No pending Google sign-in to confirm.');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final cred = await _auth.signInWithCredential(credential);
    final uid = cred.user?.uid;
    if (uid == null) throw StateError('Google sign-in did not return a user.');

    final existingDoc = await _firestore.collection('users').doc(uid).get();
    if (!existingDoc.exists) {
      final userModel = UserModel(
        id: uid,
        email: cred.user?.email ?? googleUser.email,
        role: UserRole.seeker,
        isVerified: cred.user?.emailVerified ?? true,
        displayName: cred.user?.displayName ?? googleUser.displayName,
        phoneNumber: null,
        city: null,
        address: null,
        tradingName: null,
        category: null,
        bio: null,
        basePrice: null,
        photoUrl: cred.user?.photoURL,
        isBanned: false,
        isSuspended: false,
      );
      await _firestore.collection('users').doc(uid).set(userModel.toMap());
      // Record that this new account accepted the Terms and Privacy Notice.
      await _firestore.collection('users').doc(uid).set(
        {
          'consent': {
            'acceptedAt': FieldValue.serverTimestamp(),
            'terms': true,
            'privacy': true,
          },
        },
        SetOptions(merge: true),
      );
      _cachedUser = userModel;
    } else {
      _cachedUser = await getCurrentUserModel();
    }
    _pendingGoogleUser = null;
    _previousUserId = uid;
    _isInitialized = true;
    notifyListeners();
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required UserRole role,
    String? name,
    bool acceptedConsent = false,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (cred.user != null) {
      final userModel = UserModel(
        id: cred.user!.uid,
        email: email,
        role: role,
        isVerified: false,
        displayName: name,
        phoneNumber: null,
        city: null,
        address: null,
        tradingName: null,
        category: null,
        bio: null,
        basePrice: null,
        photoUrl: null,
        isBanned: false,
        isSuspended: false,
      );

      final userMap = userModel.toMap();
      // Explicit consent record persisted with the profile so a new
      // email/password account carries its acceptance timestamp.
      if (acceptedConsent) {
        userMap['consent'] = {
          'acceptedAt': FieldValue.serverTimestamp(),
          'terms': true,
          'privacy': true,
        };
      }

      await _firestore
          .collection('users')
          .doc(cred.user!.uid)
          .set(userMap);

      if (!cred.user!.emailVerified) {
        await cred.user!.sendEmailVerification();
      }

      // Populate the cache immediately so a caller that checks
      // currentUserModel right after signUp() resolves sees the new
      // user rather than a possibly-still-null cache.
      _previousUserId = cred.user!.uid;
      _cachedUser = userModel;
      _isInitialized = true;
      notifyListeners();
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Google sign-in may not have been used; ignore.
    }
    await _auth.signOut();
    // Listener will handle notifyListeners
  }

  @override
  Future<void> resetPassword(String email) async {
    final custom = _authEmailService;
    if (custom != null && custom.customEnabled) {
      // Branded transport: one request only, no Firebase fallback, and the
      // answer never reveals whether the address exists.
      final result = await custom.requestPasswordReset(email);
      if (result.outcome == AuthEmailOutcome.sent ||
          result.outcome == AuthEmailOutcome.rateLimited) {
        // Both are "accepted" answers from the backend (the rate-limit
        // answer is deliberately uniform), so the UI shows the same neutral
        // confirmation in either case.
        return;
      }
      throw AuthEmailException(result);
    }
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toMap());
      _cachedUser = user;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
      }
      rethrow;
    }
  }

  // NEW METHOD: Update user profile (for profile setup screen)
  Future<void> updateUserProfile(UserModel user) async {
    await updateUser(user);
  }

  // ADDITIONAL HELPER METHOD: Set current user (useful for testing)
  void setCurrentUser(UserModel user) {
    _cachedUser = user;
    notifyListeners();
  }
}
