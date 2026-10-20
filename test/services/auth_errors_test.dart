import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:sangaso/src/services/auth_errors.dart';

void main() {
  group('friendlyAuthError', () {
    test('maps wrong password / invalid credential to a clear message', () {
      const expected = 'That email or password is incorrect. Please try again.';
      expect(friendlyAuthError(FirebaseAuthException(code: 'wrong-password')), expected);
      expect(friendlyAuthError(FirebaseAuthException(code: 'invalid-credential')), expected);
      expect(
          friendlyAuthError(FirebaseAuthException(code: 'invalid-login-credentials')), expected);
    });

    test('maps signup errors', () {
      expect(
          friendlyAuthError(FirebaseAuthException(code: 'email-already-in-use')),
          contains('already exists'));
      expect(
          friendlyAuthError(FirebaseAuthException(code: 'weak-password')),
          contains('too weak'));
    });

    test('network errors ask to retry', () {
      expect(
          friendlyAuthError(FirebaseAuthException(code: 'network-request-failed')),
          contains('Network'));
    });

    test('never leaks raw exception payloads for unknown codes', () {
      final e = FirebaseAuthException(code: 'unknown-thing', message: 'raw internal detail');
      final text = friendlyAuthError(e);
      expect(text.contains('raw internal detail'), isFalse);
      expect(text.length, lessThan(140));
    });

    test('falls back safely for non-Firebase errors', () {
      expect(friendlyAuthError(Exception('secret stack detail')),
          'Something went wrong. Please try again shortly.');
    });

    test('Google DEVELOPER_ERROR platform failures produce the generic safe message', () {
      final e = PlatformException(code: 'sign_in_failed', message: 'com.google.android.gms.common.ApiException: 10:');
      final text = friendlyAuthError(e, operation: 'google_sign_in');
      expect(text, 'Something went wrong. Please try again shortly.');
      expect(text.contains('ApiException'), isFalse);
    });

    test('accepts an operation label without changing user-facing text', () {
      expect(
          friendlyAuthError(Exception('x'), operation: 'email_sign_in'),
          'Something went wrong. Please try again shortly.');
      expect(
          friendlyAuthError(FirebaseAuthException(code: 'invalid-email'), operation: 'email_sign_up'),
          contains("doesn't look right"));
    });
  });
}
