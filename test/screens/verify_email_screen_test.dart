import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sangaso/src/features/auth/presentation/verify_email_screen.dart';
import 'package:sangaso/src/models/user_model.dart';
import 'package:sangaso/src/services/auth_service.dart';
import 'package:sangaso/src/services/email_verification_service.dart';

import '../fakes/fake_auth_service.dart';

/// Test double for EmailVerificationService — no Firebase.
class FakeEmailVerificationService implements EmailVerificationService {
  FakeEmailVerificationService({this.verifiedInitially = false, this.sendError});

  bool verifiedInitially;
  final Object? Function()? sendError;
  int reloadCount = 0;
  int sentCount = 0;
  bool verifiedAfterReload = false;

  @override
  bool get isSignedIn => true;

  @override
  String get currentUserEmail => 'user@example.com';

  @override
  bool get currentEmailVerified => verifiedInitially && verifiedAfterReload;

  @override
  Future<bool> reloadAndCheckVerified() async {
    reloadCount++;
    verifiedAfterReload = true;
    return verifiedInitially;
  }

  @override
  Future<void> sendVerificationEmail() async {
    sentCount++;
    final error = sendError?.call();
    if (error != null) throw error;
  }
}

Widget verifyHarness({
  required AuthService auth,
  required EmailVerificationService verification,
}) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: auth),
        Provider<EmailVerificationService>.value(value: verification),
      ],
      child: const MaterialApp(home: VerifyEmailScreen()),
    );

void main() {
  testWidgets('renders user email, instructions and resend countdown',
      (tester) async {
    final auth = FakeAuthService(currentUserModel: UserModel(
      id: 'u1',
      email: 'user@example.com',
      role: UserRole.seeker,
      isVerified: false,
    ));
    final verification = FakeEmailVerificationService();

    await tester.pumpWidget(verifyHarness(auth: auth, verification: verification));
    await tester.pump();

    expect(find.text('Verify Your Email'), findsOneWidget);
    expect(find.text('user@example.com'), findsOneWidget);
    expect(find.textContaining('Resend in '), findsOneWidget);
    expect(find.text("'ve Verified - Check Now"), findsNothing);
    expect(find.text('I\'ve Verified - Check Now'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);
  });

  testWidgets('manual recheck calls reload and stays on screen when unverified',
      (tester) async {
    final auth = FakeAuthService(currentUserModel: UserModel(
      id: 'u1',
      email: 'user@example.com',
      role: UserRole.seeker,
      isVerified: false,
    ));
    final verification = FakeEmailVerificationService();

    await tester.pumpWidget(verifyHarness(auth: auth, verification: verification));
    await tester.pump();

    await tester.tap(find.text('I\'ve Verified - Check Now'));
    await tester.pump();

    expect(verification.reloadCount, 1);
    expect(find.text('Verify Your Email'), findsOneWidget);
  });

  testWidgets('resend button is disabled during the cooldown', (tester) async {
    final auth = FakeAuthService(currentUserModel: UserModel(
      id: 'u1',
      email: 'user@example.com',
      role: UserRole.seeker,
      isVerified: false,
    ));
    final verification = FakeEmailVerificationService();

    await tester.pumpWidget(verifyHarness(auth: auth, verification: verification));
    await tester.pump();

    final resendButton = tester.widget<OutlinedButton>(
        find.ancestor(
            of: find.textContaining('Resend in '),
            matching: find.byType(OutlinedButton)));
    expect(resendButton.onPressed, isNull);
    expect(verification.sentCount, 0);
  });

  testWidgets('resend failure shows friendly message, not raw exception',
      (tester) async {
    final auth = FakeAuthService(currentUserModel: UserModel(
      id: 'u1',
      email: 'user@example.com',
      role: UserRole.seeker,
      isVerified: false,
    ));
    final verification = FakeEmailVerificationService(
      sendError: () => FirebaseAuthException(code: 'too-many-requests'),
    );

    await tester.pumpWidget(verifyHarness(auth: auth, verification: verification));
    await tester.pump();

    // Advance fake time until the cooldown expires.
    for (var i = 0; i < 40; i++) {
      if (find.text('Resend Verification Email').evaluate().isNotEmpty) break;
      await tester.pump(const Duration(seconds: 1));
    }

    final resendButton = find.ancestor(
        of: find.text('Resend Verification Email'),
        matching: find.byType(OutlinedButton));
    expect(tester.widget<OutlinedButton>(resendButton).onPressed, isNotNull);

    await tester.ensureVisible(resendButton);
    await tester.pumpAndSettle();
    await tester.tap(resendButton);
    await tester.pump();

    expect(verification.sentCount, 1);
    expect(find.text('Too many attempts. Please wait a moment and try again.'),
        findsOneWidget);
    expect(find.textContaining('FirebaseAuthException'), findsNothing);
  });
}
