import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:sangaso/src/services/auth_email_service.dart';
import 'package:sangaso/src/services/email_verification_service.dart';

/// Records requests and replays canned responses.
class _FakeTransport implements AuthEmailTransport {
  final List<Map<String, dynamic>> requests = [];
  AuthEmailHttpResponse? response;

  @override
  Future<AuthEmailHttpResponse> postJson(
    String url,
    Map<String, dynamic> body,
  ) async {
    requests.add(body);
    return response ?? const AuthEmailHttpResponse(200, '{"ok":true}');
  }
}

/// Marker thrown by the mock when Firebase's own sendEmailVerification is
/// reached, so tests can prove which transport was used.
class _FirebasePathUsed implements Exception {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  setUp(() {
    mockUser = MockUser(
      uid: 'u1',
      email: 'user@example.com',
      isEmailVerified: false,
    );
    mockAuth = MockFirebaseAuth(
      signedIn: true,
      mockUser: mockUser,
    );
  });

  group('verification transport selection', () {
    test('custom mode disabled keeps Firebase as the sender', () async {
      final transport = _FakeTransport();
      final service = FirebaseAuthEmailVerificationService(
        auth: mockAuth,
        authEmailService: AuthEmailService(
          transport: transport,
          customEnabled: false,
          idTokenProvider: () async => 'token',
        ),
      );

      whenCalling(Invocation.method(#sendEmailVerification, [null]))
          .on(mockUser)
          .thenThrow(_FirebasePathUsed());

      await expectLater(
        service.sendVerificationEmail(),
        throwsA(isA<_FirebasePathUsed>()),
        reason: 'with the switch off, Firebase must still send the email',
      );
      expect(transport.requests, isEmpty);
    });

    test('custom mode enabled calls the backend exactly once and not Firebase',
        () async {
      final transport = _FakeTransport()
        ..response =
            const AuthEmailHttpResponse(200, '{"ok":true,"sent":true}');
      final service = FirebaseAuthEmailVerificationService(
        auth: mockAuth,
        authEmailService: AuthEmailService(
          transport: transport,
          customEnabled: true,
          endpoint: 'https://www.sangaso.com/api/auth-mail.php',
          idTokenProvider: () async => 'token',
        ),
      );

      whenCalling(Invocation.method(#sendEmailVerification, [null]))
          .on(mockUser)
          .thenThrow(_FirebasePathUsed());

      await service.sendVerificationEmail();

      expect(transport.requests, hasLength(1));
      expect(transport.requests.first['action'], 'verify_email');
      expect(transport.requests.first['idToken'], 'token');
    });

    test('custom failure does not fall back to Firebase (no duplicate mail)',
        () async {
      final transport = _FakeTransport()
        ..response = const AuthEmailHttpResponse(
            503, '{"ok":false,"error":"auth_mail_not_configured"}');
      final service = FirebaseAuthEmailVerificationService(
        auth: mockAuth,
        authEmailService: AuthEmailService(
          transport: transport,
          customEnabled: true,
          idTokenProvider: () async => 'token',
        ),
      );

      whenCalling(Invocation.method(#sendEmailVerification, [null]))
          .on(mockUser)
          .thenThrow(_FirebasePathUsed());

      await expectLater(
        service.sendVerificationEmail(),
        throwsA(isA<AuthEmailException>()),
        reason: 'a failed custom request must not silently resend via Firebase',
      );
      expect(transport.requests, hasLength(1));
    });
  });
}
