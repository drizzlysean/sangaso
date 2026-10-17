import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sangaso/src/services/admin_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdminService', () {
    late FakeFirebaseFirestore firestore;
    late AdminService admin;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      admin = AdminService(firestore: firestore);

      await firestore.collection('users').doc('p-verified').set({
        'displayName': 'Dave Plumbing',
        'email': 'dave@example.com',
        'role': 'provider',
        'isVerified': true,
        'isBanned': false,
      });
      await firestore.collection('users').doc('p-pending').set({
        'displayName': 'Nami Electrical',
        'email': 'nami@example.com',
        'role': 'provider',
        'isVerified': false,
      });
      await firestore.collection('users').doc('s-1').set({
        'displayName': 'Jane Seeker',
        'email': 'jane@example.com',
        'role': 'seeker',
      });

      await firestore.collection('bookings').add({
        'seekerId': 's-1',
        'providerId': 'p-verified',
        'status': 'completed',
        'price': 300,
        'createdAt': DateTime(2026, 10, 10),
      });
      await firestore.collection('bookings').add({
        'seekerId': 's-1',
        'providerId': 'p-verified',
        'status': 'inProgress',
        'price': 120,
        'createdAt': DateTime(2026, 10, 12),
      });
      await firestore.collection('bookings').add({
        'seekerId': 's-1',
        'providerId': 'p-pending',
        'status': 'completed',
        'price': 80,
        'createdAt': DateTime(2026, 10, 14),
      });
    });

    test('getPlatformStats counts users, bookings and revenue', () async {
      final stats = await admin.getPlatformStats();

      expect(stats['totalUsers'], 3);
      expect(stats['providers'], 2);
      expect(stats['seekers'], 1);
      expect(stats['verifiedProviders'], 1);
      expect(stats['pendingKYC'], 1);
      expect(stats['totalBookings'], 3);
      expect(stats['completedBookings'], 2);
      expect(stats['activeBookings'], 1);
      expect(stats['totalRevenue'], closeTo(380.0, 0.001));
    });

    test('approveKYC verifies a provider', () async {
      await admin.approveKYC('p-pending');

      final doc = await firestore.collection('users').doc('p-pending').get();
      expect(doc.data()!['isVerified'], isTrue);
      expect(doc.data()!.containsKey('kycRejectionReason'), isFalse);
    });

    test('rejectKYC records a visible reason and clears verified flag',
        () async {
      await admin.rejectKYC('p-pending', 'ID document unreadable');

      final doc = await firestore.collection('users').doc('p-pending').get();
      expect(doc.data()!['isVerified'], isFalse);
      expect(doc.data()!['kycRejectionReason'], 'ID document unreadable');
    });

    test('updateUserStatus bans and un-bans users', () async {
      await admin.updateUserStatus('s-1', isBanned: true);
      expect(
          (await firestore.collection('users').doc('s-1').get())
              .data()!['isBanned'],
          isTrue);

      await admin.updateUserStatus('s-1', isBanned: false);
      expect(
          (await firestore.collection('users').doc('s-1').get())
              .data()!['isBanned'],
          isFalse);
    });

    test('searchUsers match names and emails without case sensitivity',
        () async {
      final snap = await admin.searchUsers('dave@example.com');
      expect(snap.map((u) => u.email), contains('dave@example.com'));

      final trading = await admin.searchUsers('nami');
      expect(trading.map((u) => u.email), contains('nami@example.com'));

      final none = await admin.searchUsers('zimbabwe-plumber');
      expect(none, isEmpty);
    });
  });
}
