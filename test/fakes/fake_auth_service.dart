import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sangaso/src/models/user_model.dart';
import 'package:sangaso/src/services/auth_service.dart';

/// Test double for AuthService — never touches Firebase.
class FakeAuthService extends ChangeNotifier implements AuthService {
  FakeAuthService({
    this.currentUserModel,
    Object? Function()? signInError,
    Object? Function()? signUpError,
    Object? Function()? googleSignInError,
    this.lastGoogleUserDisplayName,
    DelayedValue<UserModel?>? signInResult,
    String? resetErrorMessage,
  })  : _signInError = signInError,
        _signUpError = signUpError,
        _googleSignInError = googleSignInError,
        _signInResult = signInResult,
        _resetError = resetErrorMessage,
        _isInitialized = true;

  final Object? Function()? _signInError;
  final Object? Function()? _signUpError;
  final String? _resetError;
  final DelayedValue<UserModel?>? _signInResult;

  @override UserModel? currentUserModel;
  bool _signInCalled = false;
  bool get signInCalled => _signInCalled;
  String? lastSignInEmail;
  String? lastSignInPassword;

  @override bool get isInitialized => _isInitialized;
  bool _isInitialized;

  @override
  Stream<UserModel?> get userChanges => Stream.value(currentUserModel);

  @override
  Future<void> signIn(String email, String password) async {
    _signInCalled = true;
    lastSignInEmail = email;
    lastSignInPassword = password;
    final error = _signInError?.call();
    if (error != null) throw error;
    final result = await _signInResult?.getValue();
    currentUserModel = result;
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
    final error = _signUpError?.call();
    if (error != null) throw error;
    currentUserModel = UserModel(
      id: 'new-user',
      email: email,
      role: role,
      isVerified: false,
      displayName: name,
    );
    lastAcceptedConsent = acceptedConsent;
    notifyListeners();
  }

  bool lastAcceptedConsent = false;

  bool _googleSignInCalled = false;
  Object? Function()? _googleSignInError;
  GoogleSignInOutcome? _googleOutcome = GoogleSignInOutcome.signedIn;
  bool get googleSignInCalled => _googleSignInCalled;
  String? lastGoogleUserDisplayName;

  /// Test hook: what the next signInWithGoogle() call reports.
  set googleOutcome(GoogleSignInOutcome outcome) => _googleOutcome = outcome;

  @override
  Future<GoogleSignInOutcome> signInWithGoogle() async {
    _googleSignInCalled = true;
    final error = _googleSignInError?.call();
    if (error != null) throw error;
    if (_googleOutcome == GoogleSignInOutcome.consentRequired) {
      return GoogleSignInOutcome.consentRequired;
    }
    currentUserModel = UserModel(
      id: 'google-user',
      email: 'google@test.sangaso.com',
      role: UserRole.seeker,
      isVerified: true,
      displayName: lastGoogleUserDisplayName ?? 'Google User',
    );
    notifyListeners();
    return GoogleSignInOutcome.signedIn;
  }

  bool _googleConsentCompleted = false;
  bool get googleConsentCompleted => _googleConsentCompleted;

  @override
  Future<void> completeGoogleConsent() async {
    _googleConsentCompleted = true;
    currentUserModel = UserModel(
      id: 'google-new-user',
      email: 'google-new@test.sangaso.com',
      role: UserRole.seeker,
      isVerified: true,
      displayName: lastGoogleUserDisplayName ?? 'Google User',
    );
    notifyListeners();
  }

  @override
  Future<void> signOut() async {
    currentUserModel = null;
    notifyListeners();
  }

  @override
  List<String> resetCalls = [];

  /// Optional error thrown by resetPassword (e.g. a branded-transport
  /// failure). Takes precedence over the Firebase-style error code.
  Object? resetError;

  @override
  Future<void> resetPassword(String email) async {
    if (resetError != null) throw resetError!;
    final code = _resetError;
    if (code != null) throw FirebaseAuthException(code: code);
    resetCalls.add(email);
  }

  bool updateUserCalled = false;
  bool throwOnUpdateUser = false;

  @override
  Future<void> updateUser(UserModel user) async {
    updateUserCalled = true;
    if (throwOnUpdateUser) {
      throw Exception('updateUser failed (injected)');
    }
    currentUserModel = user;
    notifyListeners();
  }

  @override
  Future<UserModel?> getCurrentUserModel() async => currentUserModel;

  @override
  Future<UserModel?> fetchUserByEmail(String email) async => currentUserModel;
}

/// Helper for controlled async results in tests.
class DelayedValue<T> {
  DelayedValue(Future<T> value) : _future = value;
  Future<T> getValue() => _future;
  final Future<T> _future;
}

/// Creates a verified UserModel used across screen tests.
UserModel verifiedUser({
  String id = 'u1',
  String email = 'test@sangaso.com',
  UserRole role = UserRole.seeker,
}) =>
    UserModel(
      id: id,
      email: email,
      role: role,
      isVerified: true,
      displayName: 'Test User',
    );
