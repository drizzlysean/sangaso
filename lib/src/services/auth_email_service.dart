import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Compile-time integration switch for the branded authentication-email
/// transport implemented by the website session (`api/auth-mail.php`).
///
/// The switch is OFF by default: the app keeps using Firebase's default
/// email sender until the website backend is deployed, configured and
/// verified. A build that intentionally targets the deployed endpoint opts
/// in explicitly:
///
///   flutter build appbundle --dart-define=SANGASO_AUTH_MAIL_CUSTOM=1
///   flutter build appbundle --dart-define=SANGASO_AUTH_MAIL_CUSTOM=1 \
///       --dart-define=SANGASO_AUTH_MAIL_ENDPOINT=https://www.sangaso.com/api/auth-mail.php
///
/// No secret is embedded in the app: the endpoint is protected by the
/// backend's own rules (a Firebase ID token for verification requests and
/// server-side rate limiting for password resets).
const bool kAuthMailCustomEnabled = bool.fromEnvironment(
  'SANGASO_AUTH_MAIL_CUSTOM',
  defaultValue: false,
);

/// Default endpoint of the website's branded auth-mail API. Overridable at
/// build time; no credential is involved.
const String kAuthMailEndpointDefault =
    'https://www.sangaso.com/api/auth-mail.php';

const String kAuthMailEndpoint = String.fromEnvironment(
  'SANGASO_AUTH_MAIL_ENDPOINT',
  defaultValue: kAuthMailEndpointDefault,
);

/// Outcomes of a branded auth-email request. Deliberately coarse: the UI
/// never learns whether a password-reset address exists.
enum AuthEmailOutcome {
  /// The custom transport is disabled; Firebase's own sender must be used.
  disabled,

  /// The server accepted the request and handed it to its mail transport.
  sent,

  /// The account's email was already verified; nothing was sent.
  alreadyVerified,

  /// The server applied its rate limit window.
  rateLimited,

  /// The server could not deliver right now (not configured, upstream or
  /// network failure).
  unavailable,

  /// The request itself was rejected (bad token, malformed email, too large).
  invalidRequest,

  /// Any other unexpected response.
  failed,
}

/// Result of a branded auth-email request.
class AuthEmailResult {
  final AuthEmailOutcome outcome;

  /// Optional machine-readable detail (never rendered raw to users).
  final String? detail;

  const AuthEmailResult(this.outcome, [this.detail]);

  bool get isSuccess =>
      outcome == AuthEmailOutcome.sent ||
      outcome == AuthEmailOutcome.alreadyVerified;

  /// True when the request was actually attempted (i.e. custom mode on).
  bool get wasAttempted => outcome != AuthEmailOutcome.disabled;
}

/// Error raised when a branded auth-email request cannot be completed.
/// Carries the outcome so the UI can show a truthful message.
class AuthEmailException implements Exception {
  final AuthEmailResult result;

  const AuthEmailException(this.result);

  AuthEmailOutcome get outcome => result.outcome;

  @override
  String toString() =>
      'AuthEmailException(${result.outcome.name}${result.detail == null ? '' : ': ${result.detail}'})';
}

/// Minimal HTTP response shape used by the transport seam.
class AuthEmailHttpResponse {
  final int statusCode;
  final String body;

  const AuthEmailHttpResponse(this.statusCode, this.body);
}

/// Transport seam: the only place a network call happens. Tests inject a
/// fake; production uses [HttpAuthEmailTransport].
abstract class AuthEmailTransport {
  Future<AuthEmailHttpResponse> postJson(
    String url,
    Map<String, dynamic> body,
  );
}

/// Production transport. Uses package:http so the app keeps working on
/// every platform it targets (Android, web, desktop).
class HttpAuthEmailTransport implements AuthEmailTransport {
  HttpAuthEmailTransport({http.Client? client}) : _client = client;

  final http.Client? _client;

  @override
  Future<AuthEmailHttpResponse> postJson(
    String url,
    Map<String, dynamic> body,
  ) async {
    final client = _client ?? http.Client();
    try {
      final response = await client
          .post(
            Uri.parse(url),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
      return AuthEmailHttpResponse(response.statusCode, response.body);
    } finally {
      if (_client == null) client.close();
    }
  }
}

/// Supplies the current signed-in user's Firebase ID token. Only used for
/// verification requests; the backend proves ownership with it and never
/// trusts a client-supplied uid or email address.
typedef AuthEmailIdTokenProvider = Future<String?> Function();

Future<String?> _firebaseIdTokenProvider() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  return user.getIdToken();
}

/// Client for the website's branded authentication-email API.
///
/// Contract implemented (derived from the website's `api/auth-mail.php`):
///   POST <endpoint>
///   Content-Type: application/json
///   {"action":"verify_email","idToken":"<firebase id token>"}
///   {"action":"password_reset","email":"<address>"}
///
/// Responses (from the website implementation):
///   200 {"ok":true,"sent":true,...}                -> sent
///   200 {"ok":true,"alreadyVerified":true,...}      -> alreadyVerified
///   200 {"ok":true,"detail":"..."}                  -> sent (password reset)
///   429 {"ok":true,"limited":true}                  -> rateLimited (uniform)
///   429 {"ok":false,"error":"rate_limited"}          -> rateLimited
///   400 {"ok":false,"error":"invalid_email"|...}    -> invalidRequest
///   401/403 {"ok":false,"error":"invalid_token"}    -> invalidRequest
///   413 {"ok":false,"error":"request_too_large"}    -> invalidRequest
///   502 {"ok":false,"error":"upstream_unavailable"} -> unavailable
///   503 {"ok":false,"error":"auth_mail_not_configured"} -> unavailable
class AuthEmailService {
  AuthEmailService({
    required AuthEmailTransport transport,
    AuthEmailIdTokenProvider? idTokenProvider,
    bool? customEnabled,
    String? endpoint,
  })  : _transport = transport,
        _idTokenProvider = idTokenProvider ?? _firebaseIdTokenProvider,
        _customEnabled = customEnabled ?? kAuthMailCustomEnabled,
        _endpoint = endpoint ?? kAuthMailEndpoint;

  final AuthEmailTransport _transport;
  final AuthEmailIdTokenProvider _idTokenProvider;
  final bool _customEnabled;
  final String _endpoint;

  /// True when this build targets the deployed, configured backend.
  bool get customEnabled => _customEnabled;

  String get endpoint => _endpoint;

  /// Requests a branded verification email for the CURRENT signed-in user.
  ///
  /// The request carries the user's Firebase ID token; the backend resolves
  /// it to the authoritative account, so no uid or email is trusted from the
  /// client. When the custom transport is disabled no request is made at
  /// all and [AuthEmailOutcome.disabled] is returned.
  Future<AuthEmailResult> requestVerificationEmail() async {
    if (!_customEnabled) {
      return const AuthEmailResult(AuthEmailOutcome.disabled);
    }
    final token = await _idTokenProvider();
    if (token == null || token.isEmpty) {
      return const AuthEmailResult(AuthEmailOutcome.invalidRequest,
          'not_signed_in');
    }
    return _post({'action': 'verify_email', 'idToken': token});
  }

  /// Requests a branded password-reset email.
  ///
  /// The response carries no information about whether the address exists:
  /// the backend answers uniformly and this client maps every accepted
  /// outcome (including its rate-limit answer) to the same neutral result.
  Future<AuthEmailResult> requestPasswordReset(String email) async {
    if (!_customEnabled) {
      return const AuthEmailResult(AuthEmailOutcome.disabled);
    }
    final address = email.trim();
    if (address.isEmpty) {
      return const AuthEmailResult(AuthEmailOutcome.invalidRequest,
          'invalid_email');
    }
    return _post({'action': 'password_reset', 'email': address});
  }

  Future<AuthEmailResult> _post(Map<String, dynamic> body) async {
    AuthEmailHttpResponse response;
    try {
      response = await _transport.postJson(_endpoint, body);
    } catch (_) {
      // Network-level failure: the server outcome is unknown, so report it
      // as unavailable rather than pretending an email was sent.
      return const AuthEmailResult(AuthEmailOutcome.unavailable, 'network');
    }
    return _mapResponse(response);
  }

  AuthEmailResult _mapResponse(AuthEmailHttpResponse response) {
    var json = <String, dynamic>{};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) json = decoded;
    } catch (_) {
      // Non-JSON body: treated as an unexpected response below.
    }
    final ok = json['ok'] == true;
    final error = (json['error'] as String?) ?? '';

    switch (response.statusCode) {
      case 200:
        if (!ok) return AuthEmailResult(AuthEmailOutcome.failed, error);
        if (json['alreadyVerified'] == true) {
          return const AuthEmailResult(AuthEmailOutcome.alreadyVerified);
        }
        if (json['limited'] == true) {
          return const AuthEmailResult(AuthEmailOutcome.rateLimited);
        }
        return const AuthEmailResult(AuthEmailOutcome.sent);
      case 400:
        if (error == 'invalid_email') {
          return const AuthEmailResult(AuthEmailOutcome.invalidRequest,
              'invalid_email');
        }
        return AuthEmailResult(AuthEmailOutcome.invalidRequest, error);
      case 401:
      case 403:
        return const AuthEmailResult(AuthEmailOutcome.invalidRequest,
            'invalid_token');
      case 413:
        return const AuthEmailResult(AuthEmailOutcome.invalidRequest,
            'request_too_large');
      case 429:
        // The backend answers password-reset rate limiting uniformly
        // (ok:true, limited:true) and verification rate limiting as
        // ok:false with error rate_limited. Both mean "not sent right now".
        return const AuthEmailResult(AuthEmailOutcome.rateLimited);
      case 502:
        return AuthEmailResult(
          AuthEmailOutcome.unavailable,
          error.isEmpty ? 'upstream_unavailable' : error,
        );
      case 503:
        return const AuthEmailResult(AuthEmailOutcome.unavailable,
            'auth_mail_not_configured');
      default:
        return const AuthEmailResult(AuthEmailOutcome.failed, 'unexpected');
    }
  }
}
