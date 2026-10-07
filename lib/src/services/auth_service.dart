import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// USE RELATIVE IMPORT INSTEAD OF PACKAGE IMPORT:
import '../models/user_model.dart'; // This should work since both are in src folder

abstract class AuthService extends ChangeNotifier {
  Stream<UserModel?> get userChanges;
  UserModel? get currentUserModel;
  bool get isInitialized;

  Future<void> signIn(String email, String password);
  Future<void> signUp({
    required String email,
    required String password,
    required UserRole role,
    String? name,
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

  FirebaseAuthService() {
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
  Future<void> signUp({
    required String email,
    required String password,
    required UserRole role,
    String? name,
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

      await _firestore
          .collection('users')
          .doc(cred.user!.uid)
          .set(userModel.toMap());

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
    await _auth.signOut();
    // Listener will handle notifyListeners
  }

  @override
  Future<void> resetPassword(String email) async {
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
