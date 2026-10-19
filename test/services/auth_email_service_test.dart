import 'package:flutter_test/flutter_test.dart';
import 'package:sangaso/src/services/auth_email_service.dart';
import 'package:sangaso/src/services/auth_errors.dart';

/// Records requests and replays canned responses.
class _FakeTransport implements AuthEmailTransport {
  final List<Map<String, dynamic>> requests = [];
  final List<String> urls = [];
  AuthEmailHttpResponse? response;
  Object? throwError;

  @override
  Future<AuthEmailHttpResponse> postJson(
    String url,
    Map<String, dynamic> body,
  ) async {
    urls.add(url);
    requests.add(body);
    if (throwError != null) throw throwError!;
    return response ?? const AuthEmailHttpResponse(200, '{"ok":true}');
  }
}

AuthEmailService _service(
  _FakeTransport transport, {
  bool customEnabled = true,
  String? token = 'id-token-abc',
}) {
  return AuthEmailService(
    transport: transport,
    customEnabled: customEnabled,
    endpoint: 'https://www.sangaso.com/api/auth-mail.php',
    idTokenProvider: () async => token,
  );
}

void main() {
  group('AuthEmailService — switch disabled', () {
    test('no custom request is made while the integration switch is off',
        () async {
      final transport = _FakeTransport();
      final service = _service(transport, customEnabled: false);

      final verification = await service.requestVerificationEmail();
      final reset = await service.requestPasswordReset('user@example.com');

      expect(verification.outcome, AuthEmailOutcome.disabled);
      expect(reset.outcome, AuthEmailOutcome.disabled);
      expect(transport.requests, isEmpty);
    });
  });

  group('AuthEmailService — verification request', () {
    test('sends action=verify_email with the current user ID token',
        () async {
      final transport = _FakeTransport()
        ..response = const AuthEmailHttpResponse(
            200, '{"ok":true,"sent":true,"detail":"accepted"}');
      final service = _service(transport);

      final result = await service.requestVerificationEmail();

      expect(result.outcome, AuthEmailOutcome.sent);
      expect(transport.requests, hasLength(1));
      expect(transport.requests.first['action'], 'verify_email');
      expect(transport.requests.first['idToken'], 'id-token-abc');
      expect(transport.requests.first.containsKey('email'), isFalse,
          reason: 'the client must not send an email address for verification');
      expect(transport.urls.first,
          'https://www.sangaso.com/api/auth-mail.php');
    });

    test('missing ID token is rejected before any request', () async {
      final transport = _FakeTransport();
      final service = _service(transport, token: null);

      final result = await service.requestVerificationEmail();

      expect(result.outcome, AuthEmailOutcome.invalidRequest);
      expect(transport.requests, isEmpty);
    });

    test('already verified is reported distinctly', () async {
      final transport = _FakeTransport()
        ..response = const AuthEmailHttpResponse(
            200, '{"ok":true,"alreadyVerified":true}');
      final service = _service(transport);

      final result = await service.requestVerificationEmail();

      expect(result.outcome, AuthEmailOutcome.alreadyVerified);
      expect(result.isSuccess, isTrue);
    });
  });

  group('AuthEmailService — verification responses', () {
    Future<AuthEmailOutcome> outcomeFor(
      int status,
      String body,
    ) async {
      final transport = _FakeTransport()
        ..response = AuthEmailHttpResponse(status, body);
      final service = _service(transport);
      final result = await service.requestVerificationEmail();
      return result.outcome;
    }

    test('401 invalid token maps to invalidRequest', () async {
      expect(
        await outcomeFor(401, '{"ok":false,"error":"invalid_token"}'),
        AuthEmailOutcome.invalidRequest,
      );
    });

    test('429 rate limit maps to rateLimited', () async {
      expect(
        await outcomeFor(429, '{"ok":false,"error":"rate_limited"}'),
        AuthEmailOutcome.rateLimited,
      );
    });

    test('503 not configured maps to unavailable', () async {
      expect(
        await outcomeFor(503, '{"ok":false,"error":"auth_mail_not_configured"}'),
        AuthEmailOutcome.unavailable,
      );
    });

    test('502 upstream failure maps to unavailable', () async {
      expect(
        await outcomeFor(502, '{"ok":false,"error":"upstream_unavailable"}'),
        AuthEmailOutcome.unavailable,
      );
    });

    test('transport failure maps to unavailable', () async {
      final transport = _FakeTransport()
        ..throwError = Exception('network down');
      final service = _service(transport);
      final result = await service.requestVerificationEmail();
      expect(result.outcome, AuthEmailOutcome.unavailable);
    });
  });

  group('AuthEmailService — password reset request', () {
    test('sends action=password_reset with the trimmed email only', () async {
      final transport = _FakeTransport()
        ..response = const AuthEmailHttpResponse(
            200, '{"ok":true,"detail":"If an account exists..."}');
      final service = _service(transport);

      final result = await service.requestPasswordReset('  user@example.com ');

      expect(result.outcome, AuthEmailOutcome.sent);
      expect(transport.requests, hasLength(1));
      expect(transport.requests.first['action'], 'password_reset');
      expect(transport.requests.first['email'], 'user@example.com');
      expect(transport.requests.first.containsKey('idToken'), isFalse,
          reason: 'reset requests are not token-authenticated by the backend');
    });

    test('empty address is rejected before any request', () async {
      final transport = _FakeTransport();
      final service = _service(transport);

      final result = await service.requestPasswordReset('   ');

      expect(result.outcome, AuthEmailOutcome.invalidRequest);
      expect(transport.requests, isEmpty);
    });

    test('uniform rate-limit answer is treated as accepted, not as failure',
        () async {
      final transport = _FakeTransport()
        ..response = const AuthEmailHttpResponse(
            429, '{"ok":true,"limited":true}');
      final service = _service(transport);

      final result = await service.requestPasswordReset('user@example.com');

      expect(result.outcome, AuthEmailOutcome.rateLimited);
    });

    test('malformed address maps to invalidRequest', () async {
      final transport = _FakeTransport()
        ..response =
            const AuthEmailHttpResponse(400, '{"ok":false,"error":"invalid_email"}');
      final service = _service(transport);

      final result = await service.requestPasswordReset('not-an-email');

      expect(result.outcome, AuthEmailOutcome.invalidRequest);
    });
  });

  group('user-facing messages', () {
    test('password-reset failures never disclose account existence', () {
      final outcomes = [
        AuthEmailOutcome.unavailable,
        AuthEmailOutcome.rateLimited,
        AuthEmailOutcome.invalidRequest,
        AuthEmailOutcome.failed,
      ];
      for (final outcome in outcomes) {
        final message = friendlyAuthEmailError(AuthEmailResult(outcome));
        expect(message.toLowerCase(), isNot(contains('no account')));
        expect(message.toLowerCase(), isNot(contains('not found')));
        expect(message.toLowerCase(), isNot(contains('does not exist')));
        expect(message.toLowerCase(), isNot(contains('already registered')));
      }
    });

    test('friendlyAuthError routes branded failures to the new messages', () {
      final message = friendlyAuthError(
        const AuthEmailException(AuthEmailResult(AuthEmailOutcome.unavailable)),
      );
      expect(message, contains('try again'));
    });
  });
}
