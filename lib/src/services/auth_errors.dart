import 'package:firebase_auth/firebase_auth.dart';

import 'auth_email_service.dart';

/// Maps FirebaseAuthException codes to user-friendly messages.
/// Always falls back to safe, plain-language text; raw exception details
/// are never shown in the UI and no internals are leaked.
String friendlyAuthError(Object error) {
  if (error is AuthEmailException) {
    return friendlyAuthEmailError(error.result);
  }
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'That email address doesn\'t look right. Please check it and try again.';
      case 'user-not-found':
        return 'We couldn\'t find an account with that email. Sign up first or check the spelling.';
      case 'user-disabled':
        return 'This account has been disabled. Contact Sangaso support for help.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'That email or password is incorrect. Please try again.';
      case 'invalid-login-credentials':
        return 'That email or password is incorrect. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists for this email. Try signing in instead.';
      case 'weak-password':
        return 'That password is too weak. Use at least 6 characters, mixing letters and numbers.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network problem. Check your connection and try again.';
      case 'operation-not-allowed':
        return 'This sign-in method isn\'t enabled yet. Please try again later.';
      case 'requires-recent-login':
        return 'For security, please sign in again and retry that action.';
      case 'channel-error':
        return 'Please fill in your email and password and try again.';
      default:
        return authMessageFallback(error.code);
    }
  }
  return 'Something went wrong. Please try again shortly.';
}

/// Safe fallback tied to known operation context (unused for now, kept for
/// screen-specific overrides).
String authMessageFallback(String code) => 'Sign-in is unavailable right now ($code). Please try again shortly.';

/// Messages for the branded authentication-email transport.
///
/// These texts never mention whether an account exists: a password-reset
/// request answers identically for known and unknown addresses.
String friendlyAuthEmailError(AuthEmailResult result) {
  switch (result.outcome) {
    case AuthEmailOutcome.rateLimited:
      return 'Too many attempts. Please wait a moment and try again.';
    case AuthEmailOutcome.unavailable:
      return 'We couldn\'t send that email right now. Please try again in a few minutes.';
    case AuthEmailOutcome.invalidRequest:
      return 'That request could not be sent. Please check the details and try again.';
    case AuthEmailOutcome.alreadyVerified:
      return 'Your email address is already verified.';
    case AuthEmailOutcome.sent:
      return 'Email sent.';
    case AuthEmailOutcome.disabled:
      return 'Email sending is unavailable right now. Please try again shortly.';
    case AuthEmailOutcome.failed:
      return 'We couldn\'t send that email right now. Please try again shortly.';
  }
}

/// Errors that should tell the user to retry rather than retype.
bool isTransientAuthError(Object error) {
  return error is FirebaseAuthException &&
      const {'network-request-failed', 'too-many-requests', 'operation-not-allowed'}
          .contains(error.code);
}
