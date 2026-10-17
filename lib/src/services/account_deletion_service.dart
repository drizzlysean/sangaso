import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Result of an account self-deletion attempt.
class AccountDeletionResult {
  final bool authDeleted;
  final bool profileDocDeleted;
  final List<String> leftoverRecords;

  const AccountDeletionResult({
    required this.authDeleted,
    required this.profileDocDeleted,
    required this.leftoverRecords,
  });

  String get summary {
    if (!authDeleted) return 'AUTH_NOT_DELETED';
    if (leftoverRecords.isEmpty) return 'DELETED';
    return 'DELETED_WITH_REMNANTS';
  }
}

/// Permanently deletes the signed-in user's account.
///
/// Truthful deletion contract (no silent "request submitted" claims):
/// - Requires the current password for Firebase re-authentication first.
/// - Deletes ownership records it can reach from the client SDK:
///   the user profile document and that provider's service listings.
/// - Deletes the Firebase Auth account itself ("deleted now").
/// - Reports every record type it could NOT delete (historical bookings,
///   messages, reviews) so the caller can be honest about remnants.
class AccountDeletionService {
  AccountDeletionService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _authOverride = auth,
        _firestoreOverride = firestore;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  /// Runs re-authentication with [password] and then performs the
  /// deletion. Throws [FirebaseAuthException] when re-authentication
  /// fails (wrong password / too many attempts).
  Future<AccountDeletionResult> deleteAccount({required String password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in user to delete.',
      );
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'no-email',
        message: 'This account has no email to re-authenticate with.',
      );
    }

    final credential =
        EmailAuthProvider.credential(email: email, password: password);
    await user.reauthenticateWithCredential(credential);

    final leftovers = <String>[];
    var profileDocDeleted = false;

    // 1. Owned service listings (best effort).
    try {
      final services = await _firestore
          .collection('services')
          .where('providerId', isEqualTo: user.uid)
          .get();
      for (final doc in services.docs) {
        await doc.reference.delete();
      }
    } catch (_) {
      leftovers.add('service listings');
    }

    // 2. Profile document.
    try {
      await _firestore.collection('users').doc(user.uid).delete();
      profileDocDeleted = true;
    } catch (_) {
      leftovers.add('profile document');
    }

    // 3. Firebase Auth account (deleted now, not a request).
    try {
      await user.delete();
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
        // Re-authentication happened right before this call; retry once.
        await user.reauthenticateWithCredential(credential);
        await user.delete();
      } else {
        rethrow;
      }
    }

    // Historical records the client SDK cannot reach are documented up
    // front: bookings keep a copy of both parties' names, chats and
    // reviews survive until a backend cascade runs.
    leftovers.addAll(['chat messages', 'past booking records', 'reviews']);

    return AccountDeletionResult(
      authDeleted: true,
      profileDocDeleted: profileDocDeleted,
      leftoverRecords: leftovers,
    );
  }
}
