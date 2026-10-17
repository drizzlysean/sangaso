import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matcher/matcher.dart' show anything;
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:sangaso/src/services/account_deletion_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AccountDeletionService', () {
    test('re-authenticates, deletes auth account, profile doc and owned services',
        () async {
      final mockUser = MockUser(
        uid: 'seeker-1',
        email: 'jane@example.com',
        isEmailVerified: true,
      );
      final auth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
      final firestore = FakeFirebaseFirestore();

      await firestore.collection('users').doc('seeker-1').set({
        'email': 'jane@example.com',
        'role': 'seeker',
      });
      await firestore.collection('services').doc('srv-1').set({
        'providerId': 'seeker-1',
        'name': 'Plumbing repair',
      });
      await firestore.collection('services').doc('srv-2').set({
        'providerId': 'other-provider',
        'name': 'Electrical work',
      });
      await firestore.collection('bookings').doc('b-1').set({
        'seekerId': 'seeker-1',
      });

      final service = AccountDeletionService(auth: auth, firestore: firestore);
      final result = await service.deleteAccount(password: 'secret');

      expect(result.authDeleted, isTrue);
      expect(result.profileDocDeleted, isTrue);
      expect(
        result.leftoverRecords,
        containsAll(['chat messages', 'past booking records', 'reviews']),
      );

      expect((await firestore.collection('users').doc('seeker-1').get()).exists,
          isFalse);
      expect(
          (await firestore.collection('services').doc('srv-1').get()).exists,
          isFalse);
      // Other providers' services are untouched.
      expect(
          (await firestore.collection('services').doc('srv-2').get()).exists,
          isTrue);
      // Client SDK cannot cascade-delete historical bookings.
      expect((await firestore.collection('bookings').doc('b-1').get()).exists,
          isTrue);
    });

    test('throws when re-authentication fails and deletes nothing', () async {
      final mockUser = MockUser(uid: 'seeker-2', email: 'x@example.com');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('seeker-2').set({'email': 'x'});

      whenCalling(Invocation.method(#reauthenticateWithCredential, [anything]))
          .on(mockUser)
          .thenThrow(FirebaseAuthException(
              code: 'invalid-credential', message: 'wrong password'));


      final service = AccountDeletionService(auth: auth, firestore: firestore);

      await expectLater(
        service.deleteAccount(password: 'wrong'),
        throwsA(isA<FirebaseAuthException>()),
      );

      expect((await firestore.collection('users').doc('seeker-2').get()).exists,
          isTrue);
    });

    test('throws when there is no signed-in user', () async {
      final auth = MockFirebaseAuth(signedIn: false);
      final service = AccountDeletionService(
        auth: auth,
        firestore: FakeFirebaseFirestore(),
      );
      await expectLater(
        service.deleteAccount(password: 'whatever'),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  });
}
