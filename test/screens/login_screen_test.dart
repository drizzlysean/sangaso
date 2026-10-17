import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sangaso/src/features/auth/presentation/login_screen.dart';
import 'package:sangaso/src/models/user_model.dart';
import 'package:sangaso/src/services/auth_service.dart';

import '../fakes/fake_auth_service.dart';

Widget loginHarness({required AuthService auth}) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('route-/'))),
      GoRoute(
          path: '/login',
          builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('route-/home'))),
      GoRoute(
          path: '/admin',
          builder: (_, __) => const Scaffold(body: Text('route-/admin'))),
      GoRoute(
          path: '/signup',
          builder: (_, __) => const Scaffold(body: Text('route-/signup'))),
    ],
  );
  return MultiProvider(
    providers: [ChangeNotifierProvider<AuthService>.value(value: auth)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('validates empty email/password', (tester) async {
    final auth = FakeAuthService();
    await tester.pumpWidget(loginHarness(auth: auth));

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(auth.signInCalled, isFalse);
    expect(find.text('Enter a valid email'), findsOneWidget);
    // Form-level validation also reports the password problem:
    expect(find.text('At least 6 characters'), findsOneWidget);
  });

  testWidgets('shows friendly error for bad credentials', (tester) async {
    final auth = FakeAuthService(
      signInError: () => FirebaseAuthException(code: 'wrong-password'),
    );
    await tester.pumpWidget(loginHarness(auth: auth));

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email address'), 'user@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'secret123');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(auth.lastSignInEmail, 'user@example.com');
    expect(auth.lastSignInPassword, 'secret123');
    expect(find.text('That email or password is incorrect. Please try again.'),
        findsOneWidget);
    expect(find.textContaining('FirebaseAuthException'), findsNothing);
  });

  testWidgets('navigates to /home after successful login (seeker)', (tester) async {
    final auth = FakeAuthService(
      signInResult: DelayedValue(Future.value(verifiedUser())),
    );
    await tester.pumpWidget(loginHarness(auth: auth));
    await tester.pump();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email address'), 'user@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'secret123');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.text('route-/home'), findsOneWidget);
  });

  testWidgets('navigates to /admin after successful admin login', (tester) async {
    final auth = FakeAuthService(
      signInResult: DelayedValue(
          Future.value(verifiedUser(id: 'admin', role: UserRole.admin))),
    );
    await tester.pumpWidget(loginHarness(auth: auth));
    await tester.pump();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email address'), 'admin@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'secret123');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.text('route-/admin'), findsOneWidget);
  });

  testWidgets('password visibility toggle works', (tester) async {
    final auth = FakeAuthService();
    await tester.pumpWidget(loginHarness(auth: auth));

    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();

    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
  });
}
