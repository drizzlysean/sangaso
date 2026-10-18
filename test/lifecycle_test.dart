import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sangaso/src/features/profile/presentation/profile_setup_screen.dart';
import 'package:sangaso/src/models/user_model.dart';
import 'package:sangaso/src/services/auth_service.dart';

import 'fakes/fake_auth_service.dart';

UserModel _verifiedIncomplete() => UserModel(
      id: 'u1',
      email: 'life@test.sangaso.com',
      role: UserRole.seeker,
      isVerified: true,
    );

void main() {
  group('email registration lifecycle', () {
    test('signUp with explicit consent records the consent flag', () async {
      final auth = FakeAuthService();
      await auth.signUp(
        email: 'new@test.sangaso.com',
        password: 'pw123456',
        role: UserRole.seeker,
        name: 'New User',
        acceptedConsent: true,
      );
      expect(auth.lastAcceptedConsent, isTrue);
      expect(auth.currentUserModel!.isVerified, isFalse,
          reason: 'new accounts enter the verification gate');
      expect(auth.currentUserModel!.displayName, 'New User');
    });

    test('verification gate then completion', () async {
      final auth = FakeAuthService();
      await auth.signUp(
          email: 'new@test.sangaso.com',
          password: 'pw123456',
          role: UserRole.seeker);
      // Unverified -> verifyEmail screen; simulate verify + complete profile.
      final completed = auth.currentUserModel!
          .copyWith(isVerified: true, displayName: 'Ann', city: 'Lusaka');
      auth.currentUserModel = completed;
      auth.notifyListeners();
      expect(completed.isVerified, isTrue);
      expect(completed.displayName, 'Ann');
    });
  });

  group('google lifecycle', () {
    test('new google account requires explicit consent', () async {
      final auth = FakeAuthService()
        ..googleOutcome = GoogleSignInOutcome.consentRequired;
      final outcome = await auth.signInWithGoogle();
      expect(outcome, GoogleSignInOutcome.consentRequired);
      expect(auth.currentUserModel, isNull,
          reason: 'no account exists before the user accepts terms');
      await auth.completeGoogleConsent();
      expect(auth.googleConsentCompleted, isTrue);
      expect(auth.currentUserModel, isNotNull);
      expect(auth.currentUserModel!.isVerified, isTrue);
    });

    test('returning google account signs in without consent step',
        () async {
      final auth = FakeAuthService(); // default outcome: signedIn
      final outcome = await auth.signInWithGoogle();
      expect(outcome, GoogleSignInOutcome.signedIn);
      expect(auth.googleConsentCompleted, isFalse,
          reason: 'returning users must never be re-consented');
      expect(auth.currentUserModel!.isVerified, isTrue);
    });
  });

  group('profile completion contract', () {
    test('verified user with all profile fields complete', () {
      final user = _verifiedIncomplete().copyWith(
        displayName: 'Ann Chanda',
        phoneNumber: '+260971000000',
        city: 'Lusaka',
        address: '12 Kabulonga Road',
        heardAbout: 'Friend or family',
      );
      expect(user.displayName, isNotEmpty);
      expect(user.city, isNotEmpty);
      expect(user.heardAbout, 'Friend or family');
    });

    test('heardAbout survives map roundtrip', () {
      final user = _verifiedIncomplete().copyWith(heardAbout: 'Play Store');
      final fromMap = UserModel.fromMap(user.toMap());
      expect(fromMap.heardAbout, 'Play Store');
    });

    test('legacy documents without heardAbout map to null', () {
      final map = _verifiedIncomplete().toMap()..remove('heardAbout');
      expect(UserModel.fromMap(map).heardAbout, isNull);
    });
  });

  group('profile setup screen flow', () {
    final messengerKey = GlobalKey<ScaffoldMessengerState>();
    Widget host(FakeAuthService auth) => MultiProvider(
          providers: [ChangeNotifierProvider<AuthService>.value(value: auth)],
          child: MaterialApp(
            scaffoldMessengerKey: messengerKey,
            home: const ProfileSetupScreen(),
          ),
        );

    testWidgets('Continue blocks on invalid step-0 fields', (tester) async {
      final auth = FakeAuthService()..currentUserModel = _verifiedIncomplete();
      await tester.pumpWidget(host(auth));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(find.text('Display name is required'), findsOneWidget);
      // Still on About you step.
      expect(find.textContaining('Step 1 of'), findsOneWidget);
      expect(auth.updateUserCalled, isFalse);
    });

    testWidgets('valid step 0 advances to Your area', (tester) async {
      final auth = FakeAuthService()..currentUserModel = _verifiedIncomplete();
      await tester.pumpWidget(host(auth));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Enter your display name'), 'Ann');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Enter your phone number'), '+260971000000');
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(find.textContaining('Step 2 of'), findsOneWidget);
      expect(find.text('City / Area'), findsOneWidget);
    });

    testWidgets('save failure shows error and allows retry', (tester) async {
      final auth = FakeAuthService()
        ..currentUserModel = _verifiedIncomplete()
        ..throwOnUpdateUser = true;
      await tester.pumpWidget(host(auth));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Enter your display name'), 'Ann');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Enter your phone number'), '+260971000000');
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Enter your city or area'), 'Lusaka');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Enter your complete address'),
          '12 Kabulonga');
      await tester.tap(find.text('Continue'));
      await tester.pump();
      // Final step: choose how heard about.
      await tester.tap(find.text('Friend or family'));
      await tester.tap(find.text('Save & Continue'));
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Error saving profile'), findsOneWidget);
      // Retry after the fake stops failing.
      messengerKey.currentState!.hideCurrentSnackBar();
      auth.throwOnUpdateUser = false;
      await tester.tap(find.text('Save & Continue'));
      await tester.pumpAndSettle();
      expect(auth.updateUserCalled, isTrue);
      expect(find.textContaining('Error saving profile'), findsNothing);
    });
  });
}

