# SANGASO APP STATE REPORT (for external review)
Date: 2026-10-18 (updated after price-fix session) · Author: build session notes · Target reader: an AI assistant helping plan release

---

## 1. Project snapshot

| Item | Value |
| --- | --- |
| Product | Sangaso — on-demand home-services marketplace in Zambia (seekers book local providers) |
| Platforms | Flutter app (Android primary), website www.sangaso.com (static SPA, separate repo) |
| Package name | `com.sangaso.app` |
| Current version | 1.0.3, versionCode 6 (release candidate in hand) |
| Stack | Flutter 3.38.5, Dart, Firebase (Auth e-mail+Google, Firestore, Storage), Cloud Firestore data model |
| Repos | github.com/drizzlysean/sangaso (app in `app/`), working branch `recovery/unified-design-2026-10-17`. `main` untouched. |
| HEAD as of this update | `42dac86` (code commits `6a03c1a` price fix, `9d217bb` password-reset seam fix) |
| CI | GitHub Actions "Build APK" workflow: produces signed AAB + APK. Dispatched with `-f build_number=<n>` to pin versionCode. |
| Sign-off chain | Upload key signing on CI (`UPLOAD_KEYSTORE_BASE64` secret), Play App Signing on Play side |
| Owner | Sean (Google account: seantinashenyakutira@gmail.com) — owns Play Console, Firebase console, cPanel website. All console actions are owner-gated (agent never gets credentials). |

## 2. Release bundle in hand (verified 2026-10-18, second rebuild)

| Fact | Value |
| --- | --- |
| CI run | 39153033573 (head commit e4a9037 on working branch) |
| File | app-release.aab |
| SHA-256 | 51d3b662afa5131ad1709ffd308b20bd92ca775aa5fa0e45e0f6f6cf4b08d2a7 |
| Size | 47,042,731 bytes |
| Package / versions | com.sangaso.app, versionName 1.0.3, versionCode 6 |
| minSdk / targetSdk | 24 / 36 (targetSdk 36 required by Play since Aug 2026) |
| Signing | `META-INF/UPLOAD.SF` + `UPLOAD.RSA` present = upload-key signed (not a new key) |
| Emulator safety | Release built WITHOUT emulator flag; a test asserts emulator mode is opt-in only |
| Branding | Authentic logo (recovered from the website repo) across app UI, launcher icon + adaptive layers + web/windows icons; asset byte-verified inside the AAB |
| Test battery before build | 83/83 tests pass, flutter analyze 0 errors / 0 warnings |

Superseded bundles (do NOT submit): versionCode 6's predecessor **1.0.3+5** (run 39121956994, SHA 4a427b1a440b155d56a89ce159d257e353aaa9bbdf6870429bb7b01e80dc7954), both 1.0.3+4 builds (runs 39028406795 branded / 39019071100 pre-branding), and 1.0.2+3 (run 39007126737).

Rationale for versionCode 6: strictly increasing counter; no confirmed Play upload of +5 existed, so +6 guarantees no collision regardless of what the owner already uploaded.

## 3. Feature status matrix

| Feature | State | Evidence |
| --- | --- | --- |
| E-mail signup → verify gate → login | DONE | 5-step onboarding, resend cooldown, friendly errors; device-verified on a real phone |
| Router lifecycle guard | DONE | Redirect: uncompleted profile → /profile-setup; unverified → /verify-email; null-safe, no loop |
| Visible T&C consent gate | DONE (this build) | Explicit unchecked-checkbox Terms + Privacy links on signup AND on the Google path; consent map (acceptedAt/terms/privacy) persisted on the users Firestore doc |
| Google sign-in two-phase | DONE (this build) | Returning Google users sign in silently; brand-new Google users get a consent dialog first (`GoogleSignInOutcome.consentRequired` → `completeGoogleConsent()`) |
| Multi-step onboarding | DONE (this build) | 3 steps: About you → Your area → Your business (provider) / "How did you hear about Sangaso" (seeker, `heardAbout` persisted); per-step validation; progress header |
| Profile completion (provider fields) | DONE | Trading name, category, bio, base price persisted; device-verified end-to-end on a real phone |
| Provider service listing CRUD | UI WALKED, upload untested | My Services empty state + Add Service form open; photo-picker step not yet completed (see §5) |
| Search + service details + booking flow | FIXED, device re-verification pending | Book Now now threads the tapped service (id) into the booking; BookingScreen loads the service and books ITS price (K1,300 case), falling back to the provider's "Starting price" label only when no service is attached. Device-verified earlier: search renders real services, details + 3-step booking form work; booking submission tap still to re-confirm on device |
| Chat (in-booking messenger) | DONE (Firestore-backed) | Live text/image chat per booking |
| FCM push notifications (client) | DONE (this build) | Permission requested after verified login; token saved to users/{uid}/fcmTokens map; removed on sign-out; re-persisted on token rotation; foreground → SnackBar; tap → routes by payload (type+relatedId → /chat/:id or /booking/:id); background handler registered |
| FCM push (server) | NOT DONE | No trusted backend exists yet to send messages; Cloud Functions + Firebase Admin/HTTP v1 required (owner-gated; billing decision needed) |
| Account deletion | Website plan only | Play requires a web or in-app deletion path; page exists in website source but site not deployed (see §6) |
| Admin dashboard | Built | Ban/suspend flows tested in unit tests |
| Play Store listing assets | NOT STARTED | Need screenshots, feature graphic, description (truthful: no unverifiable claims) |

## 4. Fresh device QA log (2026-10-18, physical Redmi via USB debug)

- Installed fresh debug APK containing all polish work → OK
- Completed provider onboarding on device (multi-step UI functions; lands on Dashboard with empty tabs) → OK
- Profile screen shows every persisted onboarding value (Kaunda / Electrical / bio / K250.00) → OK
- My Services → Add Service form opens → OK
- Could NOT finish the photo/upload step: the phone kept spawning media surfaces (YouTube picture-in-picture overlay was silently stealing taps; focus jumped to WhatsApp and a music player twice). Not app bugs — device environment. Nothing was sent from WhatsApp.
- Second session (2026-10-18 evening): the phone stayed OFFLINE on USB all session — device QA could not resume. The price-fix build has therefore NOT been device-verified. Unverified on device: photo upload, booking Confirm navigation, Google sign-in consent dialog, notification tap routing, logout + account deletion.

## 5. Known open items / bugs

1. ~~**Booking price mismatch (REAL, needs decision)**~~ **RESOLVED 2026-10-18 (commit 6a03c1a)** — root cause: the funnel dropped the selected service at Book Now; bookings were created from provider profile defaults (category + basePrice = K1,000) while the card showed the service's own price (K1,300); BookingModel had no service reference at all. Fix: bookings now carry the tapped service (nullable serviceId/serviceName persisted, legacy docs read as null); booking price = the service's price; honest "Starting price" label in the no-service fallback. Regression tests added (service-price persistence, legacy doc compatibility). No production bookings were created or modified.
2. **One QA-written bio contains a typo** ("FastFast installs...") from the test-input method — cosmetic, fix in Edit Profile.
3. **"Skip for now" was removed from onboarding** — router forces completion; confirm the owner WANTS mandatory onboarding (it is safer for data quality, but is a product decision).
4. Booking submission tap → success navigation never re-confirmed on device.
5. No automated test of the photo-upload flow (image_picker + Firebase Storage) — verify manually first.
6. Play listing assets not prepared yet.
7. Password-reset dialog bypassed the AuthService seam (called FirebaseAuth directly) — FIXED (commit 9d217bb), now routed through AuthService.resetPassword with 2 new tests.

## 6. External blockers (coordinated, not code)

1. **LEGAL PAGES NOT LIVE (release blocker)**: live https://www.sangaso.com/?page=terms,+privacy,+delete-account all currently return the SPA landing page instead of legal content (identical 170kB landing body); /terms.php 404. The website source contains the multi-page routing patch, but it is NOT deployed (owner must deploy via their own cPanel/hosting session). Until it goes live the in-app legal links show wrong content — the Play submission "Privacy policy" field must not claim they work, and the description must avoid citing them as final.
2. **Google sign-in provider config**: Google provider must be enabled in Firebase Auth for the production app before upload (owner console action; SHA-1/SHA-256 of the upload key may need registering in the Firebase project settings).
3. **FCM real delivery** needs a small trusted backend (Cloud Function on booking/message writes calling HTTP v1) — requires the owner's authorization for billing; the app side is already consuming.
4. **Account deletion page** must go live together with the legal pages patch (Play account-deletion policy).

## 7. Credentials hygiene note

The owner's Gmail password was pasted in chat earlier (2026-10-17) — REQUIRED OWNER ACTION: rotate that Google account password (myaccount.google.com → Security → Password) and enable 2-Step Verification, then review recent sign-in activity. The password itself is deliberately NOT reproduced in this report. No API keys, tokens, or other secrets were shared in chat; nothing else requires rotation. Agent sessions never request credentials; all console actions are performed by the owner.

## 8. Test accounts that exist in PRODUCTION Firebase

- seantinashenyakutira@gmail.com — real owner account (provider; "Steven kaunda"); keep
- rastaferi73@gmail.com (provider; device-loaded account) — temp QA account
- qa.seeker.1017@qateam.test — created in PRODUCTION by QA, unverified and unusable (fake domain); owner authorized deletion: delete from Firebase Auth (console → Authentication → Users) AND the matching users/{uid} Firestore doc; there is no flag separating QA accounts from customers, so future QA signups should keep the qa-* naming convention

## 9. Ordered "what next" plan (updated after price-fix session)
Track A — unblock the WEBSITE (owner, one session):
1. Deploy the multi-page routing patch so ?page=terms|privacy|delete-account serve real content.
2. Verify each URL loads in a browser (re-verified 2026-10-18: STILL NOT DEPLOYED — all three URLs return the SPA landing page, /terms.php is 404); then app-store legal links become true.

Track B — finish device QA (agent, after phone is reconnected):
1. Install a fresh price-fix debug build (or the release AAB via bundletool) and complete the photo upload flow with the temp provider account.
2. Book the published service as a seeker; verify Review & Confirm now shows the SERVICE price; confirm booking submission navigates; then in-booking chat.
3. Walk logout → account deletion (web URL) and notification tap routing.
4. On Google sign-in: verify the consent dialog for a brand-new account (needs owner to have enabled the Google provider in Firebase first).

Track C — Play submission (owner + agent):
1. Owner enables Google provider in Firebase (if Google sign-in is to be marketed), checks SHA keys.
2. Prepare store listing: description, feature graphic, 2-8 screenshots (capture from device), privacy policy URL (must become real first), account deletion URL.
3. Owner uploads app-release.aab (1.0.3+6, SHA 51d3b662…) to the Internal testing track, adds a tester e-mail list, rolls out.
4. Only after internal testing is green AND real FCM backend is wanted: owner approves a Cloud Function deployment; then closed testing (20+ testers, 14 days) in preparation for production. Do not invent a public listing URL or claim public availability.

Track D — small code follow-ups (agent, before submission):
1. ~~Decide + fix the price mismatch~~ DONE (6a03c1a).
2. ~~Password reset through AuthService~~ DONE (9d217bb).
3. Add a widget test for the BookingScreen review rows (service price shown, fallback label honest) — depends on injectable Firestore in that screen; candidate refactor.
4. Keep versionCode > 6 on any rebuild (`-f build_number=<n+1>` and re-verify SHA/signature before every upload).

## 10. How to rebuild and verify (PowerShell, this machine)

```
$env:PATH = "C:\tools\flutter-sdk\flutter\bin;$env:PATH"
$env:ANDROID_SDK_ROOT = "C:\tools\android-sdk"
$env:JAVA_HOME = "C:\tools\jdk17\jdk-17.0.20.1+1"
cd C:\Users\MRSEANNYAKUTIRA\Desktop\Sangaso\app
flutter test                      # 79 tests expected green
flutter analyze                   # 0 errors, 0 warnings expected
gh workflow run "Build APK" -R drizzlysean/sangaso --ref recovery/unified-design-2026-10-17 -f build_number=<n>
# then verify: hash, size, bundletool dump manifest, META-INF/UPLOAD.* entries
```

---

## 10. Branded authentication-email integration (prepared, DISABLED by default)

### Endpoint contract actually inspected
Source: website repository `drizzlysean/sangaso` (separate), branch
`recovery/final-website-release-2026-10-17`, commit `66d098e`, files
`public_html/api/auth-mail.php`, `api/auth-mail-lib.php`,
`api/mail-templates.php` (read-only inspection; the website session owns
that code).

```
POST https://www.sangaso.com/api/auth-mail.php
Content-Type: application/json

{"action":"verify_email","idToken":"<firebase id token>"}
{"action":"password_reset","email":"<address>"}
```

Responses implemented by the backend:
| Status | Body | Meaning |
| --- | --- | --- |
| 200 | `{"ok":true,"sent":true,"detail":...}` | verification sent |
| 200 | `{"ok":true,"alreadyVerified":true,...}` | already verified, nothing sent |
| 200 | `{"ok":true,"detail":...}` | password reset accepted (uniform) |
| 429 | `{"ok":true,"limited":true}` | password-reset rate limit (uniform, no account info) |
| 429 | `{"ok":false,"error":"rate_limited"}` | verification rate limit |
| 400 | `{"ok":false,"error":"invalid_email"}` / other | malformed request |
| 401/403 | `{"ok":false,"error":"invalid_token"}` | token not valid |
| 413 | `{"ok":false,"error":"request_too_large"}` | payload too large |
| 502 | `{"ok":false,"error":"upstream_unavailable"|"delivery_failed"}` | sending failed |
| 503 | `{"ok":false,"error":"auth_mail_not_configured"}` | service account / sender / mailer not configured |

Backend prerequisites (owner): `SANGASO_FB_SA_JSON` or `SANGASO_FB_SA_PATH`
(service account), `SANGASO_CONTACT_EMAIL` (sender), `SANGASO_SITE_URL`
(continueUrl base, defaults to sangaso.com). The backend delivers through
the host mailer `mail()`; no transactional provider is configured yet.
The backend also enforces a same-origin guard: browsers must send a
matching `Origin` (mobile builds send none, which the backend accepts).

### App call sites updated
- NEW `lib/src/services/auth_email_service.dart` — `AuthEmailService`
  (transport seam `AuthEmailTransport`, production `HttpAuthEmailTransport`),
  `AuthEmailOutcome`, `AuthEmailResult`, `AuthEmailException`, plus the
  compile-time switch `SANGASO_AUTH_MAIL_CUSTOM` and endpoint override
  `SANGASO_AUTH_MAIL_ENDPOINT`.
- `lib/src/services/email_verification_service.dart` — resend now uses the
  branded endpoint when the switch is on; exactly one request, no Firebase
  fallback after a failed custom request.
- `lib/src/services/auth_service.dart` — `resetPassword()` uses the branded
  endpoint when the switch is on; the backend's uniform answers (sent and
  rate-limited) both map to the same neutral confirmation, so the UI never
  discloses whether an account exists.
- `lib/src/services/auth_errors.dart` — new truthful messages for the
  branded failure modes (rate limit, unavailable, invalid request).
- `lib/main.dart` — constructs `AuthEmailService` and injects it into
  `FirebaseAuthService` and `FirebaseAuthEmailVerificationService`;
  provided via Provider.
- `pubspec.yaml` — added `http: ^1.2.2` (runtime) and
  `mock_exceptions: ^0.8.2` (dev only, for the transport-selection test).

### How the integration is gated
`SANGASO_AUTH_MAIL_CUSTOM=1` at build time. Default is OFF, so every
current build keeps using Firebase's default email sender. Nothing in the
app changes behaviour until a build explicitly opts in, and the switch is
meant to be enabled only in a build that targets a deployed, configured
and verified endpoint. No secret is embedded: verification requests carry
the user's own Firebase ID token (the backend proves ownership), password
resets rely on the backend's IP/address rate limiting.

### Focused checks actually performed
- `flutter test test/services/auth_email_service_test.dart` (15 tests) —
  request construction, response mapping (200 sent, 200 alreadyVerified,
  400/401/413 invalid, 429 rate limit, 502/503 unavailable, transport
  failure), no request while the switch is off, no email/idToken leakage
  in the wrong request shape, privacy-safe user messages.
- `flutter test test/services/auth_email_transport_test.dart` (3 tests) —
  switch off keeps Firebase as sender; switch on calls the backend exactly
  once and never Firebase; a failed custom request does NOT fall back to
  Firebase (no duplicate email).
- `flutter test test/screens/login_screen_test.dart` (8 tests, incl. 1 new)
  — the branded reset failure message never says the account is unknown.
- `flutter test test/screens/verify_email_screen_test.dart` and
  `test/lifecycle_test.dart` — unchanged behaviour confirmed.
- `flutter analyze` — 0 errors, 0 warnings.
- No email was sent and no request was made to the production endpoint
  during this work (all traffic went through the fake transport).

### Custom delivery status
DISABLED and UNVERIFIED. Branded delivery is only real once the website
session deploys `api/auth-mail.php`, the service account and sender are
configured in cPanel, the mail transport actually delivers, and an
authorized test inbox receives a working branded email. Until then the
shipped app continues to use Firebase's default sender.

### Remaining dependencies and next owner actions
1. Website session: deploy the candidate (owner cPanel session), set
   `SANGASO_FB_SA_JSON`/`SANGASO_FB_SA_PATH`, `SANGASO_CONTACT_EMAIL`,
   `SANGASO_SITE_URL`; confirm the mailer is configured for the domain.
2. Verify one branded verification email AND one branded password-reset
   email arrive in an authorized inbox and that their action links work.
3. Then produce the next release: bump versionCode above 6, build with
   `--dart-define=SANGASO_AUTH_MAIL_CUSTOM=1`, verify the new AAB's
   SHA-256/signature, and update the release reports. The current
   1.0.3+6 artifact (SHA 51d3b662a...) stays preserved and is NOT
   rebuilt by this integration.
4. Firebase Console: authorized domains and the email action URL must stay
   on the deployed `https://sangaso.com/auth-action.php` (unchanged).

---

## 11. Final closed-test distribution check (2026-10-19)

### Verified from the repository and artifacts
- Branch `recovery/unified-design-2026-10-17`, HEAD `f36946d`, working tree clean.
- Artifacts preserved: `artifacts/app-release.aab` = 1.0.3+7 (SHA-256
  `2a4fa610aa9dd1ff0422b6583fae819b480f21c0cb11be400b84030cdfb6b2f5`,
  47,045,542 B); `artifacts/app-release-1.0.3+6.aab` = 1.0.3+6 (SHA-256
  `51d3b662afa5131ad1709ffd308b20bd92ca775aa5fa0e45e0f6f6cf4b08d2a7`).
- +7 build lineage: CI run `39274465515`, head `22a8713`, success,
  2026-10-19T15:02:53Z; versionCode 7 / versionName 1.0.3 / package
  `com.sangaso.app` / minSdk 24 / targetSdk 36; upload key unchanged
  (SHA1 1D:2F:AB:F4:74:09:37:21:D7:80:39:A9:71:FE:08:F5:68:37:F7:68,
  SHA256 D8:AA:55:3B:0E:AB:74:58:37:F0:E2:87:42:AA:19:70:31:9C:3B:3C:49:85:E0:8D:56:9C:D4:74:76:1C:B6:1A);
  branding asset present; `default_web_client_id` and its value confirmed
  inside the packaged `base/resources.pb`.
- Firebase config shipped: project `ondemand-a16d1`, sender `445535100693`,
  Android appId `1:445535100693:android:443a648147302e0ceb531c`, apiKey
  present (masked). Android registration in code: namespace and
  applicationId both `com.sangaso.app`.
- OAuth: `default_web_client_id` =
  `445535100693-r4q7ns9ra7gaf43gc9i79ha1clldmtvc.apps.googleusercontent.com`;
  its project-number prefix `445535100693` matches the Firebase project
  number, so it belongs to the same GCP project. Note: this is the
  **Android** OAuth client (client_type 3) — the name is historical. The
  website's web client is a different id
  (`445535100693-nv9j7f6cfsn475r4hobanparifsc73it`).
- Auth-email integration: `auth_email_service.dart` exists at the +7 build
  commit and is imported by `main.dart`; commit `139223e` IS an ancestor of
  `22a8713` (the +7 build commit). The switch `SANGASO_AUTH_MAIL_CUSTOM`
  defaults to false and the CI workflow passes no such dart-define, so the
  custom sender is OFF in +7. Artifact scan confirms it: auth-email string
  literals are absent from `libapp.so` while strings from other commits
  (e.g. "Starting price") are present — the dead custom-mode branch is
  compiled out. Version 7 therefore uses Firebase's default sender and can
  be tested independently of the branded-email integration.

### Correction to the stated premise
"1.0.3+7 was created before the auth-email integration" is not accurate.
The integration commit `139223e` predates the +7 build commit `22a8713`, so
the +7 source tree includes the integration; only its code path is compiled
out because the switch is off.

### Cannot be verified without the owner's Play Console / Firebase screens
- Whether a Firebase Android registration with package `com.sangaso.app`
  exists (the repo carries no google-services.json and the app never reads
  the package from Firebase config).
- Which SHA-1/SHA-256 fingerprints are registered on that registration.
- The Play App Signing SHA-1 value and whether it is registered on the
  OAuth client the app uses.
- Play Console closed-test state (release in review, track, tester list,
  opt-in URL) and the website legal-page live status.

### Owner checklist for distributing 1.0.3+7 through Closed testing
1. Play Console -> your app -> Testing -> Closed testing -> Manage track:
   confirm the release "Sangaso Closed Test 1.0.3" carries versionCode 7.
2. Tester list: add a Google Group under the track; copy the opt-in URL
   (Testing -> Closed testing -> Testers tab -> "How testers join") and
   send it to testers.
3. App content -> Privacy policy: the URL must serve a real policy. As of
   this check `https://www.sangaso.com/?page=privacy` still returns the
   marketing landing page (170,622 bytes, no policy text) - deploy the
   website multi-page patch or change the URL before publishing.
4. App content -> Data safety, Content rating, Target audience, Ads,
   App access, Government/Health/Financial: all green (answers pre-written
   in reports/PLAY_LISTING_PACK.md).
5. Store listing: name, short + full description, icon 512x512, feature
   graphic 1024x500, at least 2 phone screenshots, support email, privacy
   URL, data-deletion URL.
6. Wait for the pre-review checks, then review, then live; confirm
   App bundle explorer shows versionCode 7.
7. After it is live: Play Console -> App integrity -> App signing key
   certificate -> copy the SHA-1 and confirm it is registered on the
   `com.sangaso.app` Firebase registration (and on the OAuth client). Only
   then does Google sign-in work in Play-installed builds.
8. Tester onboarding: open the opt-in URL signed into the right Google
   account -> Become a tester -> accept Play terms -> install from Play.
9. Tester expectations for this build: email/password sign-in works;
   Google sign-in may fail until the Play SHA-1 is registered; no push
   notifications; emails come from Firebase's default sender.
10. Keep the closed test running with 20 testers opted in continuously for
    14 days (12 for older developer accounts) before applying to
    production, and do not skip the open-testing track.

### Rebuild recommendation
No rebuild is required to distribute 1.0.3+7. Registering the Play App
Signing SHA-1 is server-side only. A new version is justified only for a
concrete requirement: enabling the branded auth-email transport (after the
website backend is deployed, configured and a real branded email is
received) or a specific code fix.

---

## 12. P0 authentication incident - diagnosis and fix (2026-10-20)

### Diagnosis (evidence, not guesswork)
- Non-mutating Identity Toolkit probes with the shipped keys returned
  `INVALID_EMAIL` (bad email) and `INVALID_LOGIN_CREDENTIALS` (sign-in with
  a non-existent address): the API is ENABLED, both API keys are valid and
  unrestricted, and the Email/Password provider is ENABLED
  (`OPERATION_NOT_ALLOWED` would appear if it were disabled). The Firebase
  backend is healthy for email auth - the email failures are client-side.
- Root cause of Google sign-in failure (confirmed source defect): commit
  22a8713 put the ANDROID OAuth client id
  (`445535100693-r4q7ns9ra7gaf43gc9i79ha1clldmtvc...`) into
  `strings.xml` as `default_web_client_id`. google_sign_in_android 6.2.1
  (GoogleSignInPlugin.java:240-246) reads that resource and uses it as
  serverClientId / requestIdToken - which must be a WEB APPLICATION
  client. A mismatched client type makes the picker fail with
  DEVELOPER_ERROR (ApiException 10, PlatformException), which is NOT a
  FirebaseAuthException, so friendlyAuthError returned the generic
  "Something went wrong. Please try again shortly." toast.
- The same generic toast for email paths means a non-FirebaseAuthException
  was thrown client-side; the code had zero diagnostic logging, so the
  exact device-side cause cannot yet be named. Safe logging was added.

### Changes (commit ce05544)
- `android/app/src/main/res/values/strings.xml`: default_web_client_id now
  carries the project's WEB client id
  `445535100693-nv9j7f6cfsn475r4hobanparifsc73it.apps.googleusercontent.com`
  (the id shown on the Firebase Google provider page), with a comment
  documenting that the resource must be a Web application client.
- `lib/src/services/auth_errors.dart`: `friendlyAuthError` gained an
  `operation` label and `_logAuthDiagnosis` - writes
  `SANGASO_AUTH_DIAG op=<op> id=<ms> type=<ExceptionType> code=<code>` to
  logcat (flutter tag). Never logs passwords, tokens, messages or emails.
- Call sites updated with operation labels: login_screen
  (email_sign_in / google_sign_in / password_reset), signup_screen
  (email_sign_up / google_sign_up), verify_email_screen (verify_email).
- Removed two unused imports flagged by the analyzer (login_screen,
  auth_email_transport_test).
- Tests: expanded `test/services/auth_errors_test.dart` with regression
  tests for PlatformException(DEVELOPER_ERROR) -> generic safe message and
  for the operation label not changing user-facing text. 25 focused auth
  tests pass; analyze: 0 errors / 0 warnings.
- pubspec.yaml: version 1.0.3+8.

### New artifact (built by CI, verified)
- `app/artifacts/app-release-1.0.3+8.aab`
  SHA-256 `2580d18910fae6d05f533ba81af61f583e5dc4b4f13a08d80c88a7384e7c8448`
  (47,046,628 B). CI run 39434591850, head ce05544, conclusion success.
- Verified: versionCode 8 / versionName 1.0.3 / package com.sangaso.app;
  embeds the NEW web client id in base/resources.pb and NOT the old one;
  contains the SANGASO_AUTH_DIAG logging; signed with the unchanged upload
  key (SHA1 1D:2F:AB:F4:74:09:37:21:D7:80:39:A9:71:FE:08:F5:68:37:F7:68).
- Preserved: app-release.aab (1.0.3+7), app-release-1.0.3+6.aab,
  app-release-1.0.3+8.aab.

### Owner Firebase/Google Cloud checks still needed
1. Google Cloud Console -> APIs & Services -> Credentials: confirm
   `445535100693-nv9j7f6cfsn475r4hobanparifsc73it...` exists as a WEB
   APPLICATION client, and that ANDROID clients exist for package
   com.sangaso.app bound to the Play App Signing SHA-1 (from Play Console
   -> App integrity), not only the upload key
   SHA1 1D:2F:AB:F4:74:09:37:21:D7:80:39:A9:71:FE:08:F5:68:37:F7:68.
   Upload-key fingerprints only help sideloaded builds; Play-installed
   builds are signed by the Play App Signing key.
2. Confirm no versionCode 8 (or higher) was ever uploaded to any Play
   track before publishing the new candidate.
3. After the next release: repro a failing email sign-in, run a logcat
   session (adb logcat -s flutter) and report the full
   SANGASO_AUTH_DIAG line plus the toast text so the client-side email
   failure can be named exactly.


---

## 13. On-device reproduction of the P0 auth incident (2026-10-20)

Device: Xiaomi M2007J22G (product cannong_global), Android 12 / SDK 31 /
MIUI 14, adb serial mjtkzp7h49onqkz5, authorized. Google Play services
present. com.sangaso.app was NOT preinstalled - no Play-signed package on
this device, hence no signature conflict at any point.

Tests (owner executed, logs captured into ignored diagnostics/):
1. Debug APK from current source (contains ce05544 fixes):
   email sign-in SUCCESS, Google sign-in SUCCESS (picker + completion),
   Google picker cancellation CLEAN.
2. Signed release candidate 1.0.3+8 installed via bundletool
   --connected-device (local sideload, debug-keystore-signed split APKs;
   exact release code/resources, no Play involvement): email sign-in
   SUCCESS, Google sign-in SUCCESS. No SANGASO_AUTH_DIAG lines and no
   Firebase/Platform/ApiException entries in the flutter logcat for any
   failing test (none failed).

Interpretation:
- The reported failures do NOT reproduce from current source on this
  device in either debug or release AOT mode.
- The +7 Google failure root cause stands (Android-type client id used as
  serverClientId -> DEVELOPER_ERROR); ce05544 fixed it and the on-device
  Google flow now completes.
- The reported email failures are not reproducible backend-side (probes)
  nor on this device; remaining explanations are device-specific GMS
  issues on the original failing device, or a paraphrased error message.
  If it recurs on the Play build, the SANGASO_AUTH_DIAG logcat line will
  identify the operation, exception type and safe error code.

Still owner-gated for PLAY-installed builds:
- This sideloaded +8 candidate is signed locally (debug keystore). A Play
  install is signed by the Play App Signing key, so the Play Console ->
  App integrity SHA-1 must be registered on the com.sangaso.app Firebase
  registration for Google sign-in on Play installs.
- Confirm before upload that no versionCode >= 8 exists on any Play track.
- Local artifacts: diagnostics/ (ignored), $TEMP\opencode\rel8.apks.
