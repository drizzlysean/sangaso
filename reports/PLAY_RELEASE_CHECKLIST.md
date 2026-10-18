# Play Release Checklist — internal testing (updated 2026-10-18)

## Artifact facts (verify before every submission)

| Item | Value | How to re-verify |
| --- | --- | --- |
| Source commit (this build) | run `39121956994`, branch `recovery/unified-design-2026-10-17`, head `107e763` (includes FINAL POLISH: consent gate, Google two-phase sign-in, multi-step onboarding, FCM wiring) | `gh run view 39121956994 -R drizzlysean/sangaso --json headSha` |
| File | `app-release.aab` from artifact `sangaso-release-aab` (kept in untracked `artifacts/`) | Actions page → artifacts |
| SHA-256 | `4a427b1a440b155d56a89ce159d257e353aaa9bbdf6870429bb7b01e80dc7954` | `(Get-FileHash app\artifacts\app-release.aab -Algorithm SHA256).Hash.ToLower()` |
| Size | 47,040,076 bytes | file properties |
| Package | `com.sangaso.app` | bundletool dump manifest |
| Version name / code | **1.0.3** / **5** | bundletool dump manifest; pubspec.yaml |
| minSdk / targetSdk | 24 / **36** (Android 16 — Play policy target since Aug 2026) | bundletool dump manifest |
| Signing | upload key (keystore from `UPLOAD_KEYSTORE_BASE64`), NOT a new key | `META-INF/UPLOAD.SF` + `UPLOAD.RSA` entries verified |
| Emulator safety | release built WITHOUT `--dart-define=SANGASO_USE_EMULATORS` | workflow yml contains no dart-define; `useEmulators` off by test |
| Branding | authentic logo; preserved original at `brand/logo-source.png`; launcher icon + adaptive layers + web/windows icons; asset byte-confirmed inside this AAB (`logo_icon.png` 55,631 B) | zip listing of app-release.aab |

Superseded artifacts (do NOT submit):
- `1.0.3+4`, run `39028406795`, SHA-256 `a1be34b116692c974ba88c783509637dfe135e853848650f4ecb659b4ce1b7e5` (branded but pre-polish; superseded by +5)
- `1.0.3+4` pre-branding, run `39019071100`, SHA-256 `b012bca420debb79dc80d2f1f3a8fee191dc4672177e844c427d9bd9de26a637`
- `1.0.2+3`, run `39007126737`, SHA-256 `dca22173e55094d8748a5ba8556be93e2c075a450ea459b740055c5d56bfe348`

## Final-polish record (commit `29c005a`, tests 79/79)

- Visible consent gate: signup + login Google flows require an explicit,
  unchecked-by-default Terms + Privacy acceptance before account
  creation; consent map (acceptedAt/terms/privacy) persisted on the
  users document at signUp (`acceptedConsent`).
- Google two-phase: `signInWithGoogle` checks an existing account first
  (returning users skip consent); new accounts return
  `GoogleSignInOutcome.consentRequired` and are only created by
  `completeGoogleConsent()`.
- Multi-step onboarding: `profile_setup_screen.dart` rewritten as
  Step 1 About you → Step 2 Your area → Step 3 Your business (provider)
  / How did you hear about Sangaso (seeker, `heardAbout` on UserModel,
  nullable + legacy-safe); per-step validation; save-failure retry kept.
  NOTE: "Skip for now" removed - the router guard requires completion.
- FCM: token lifecycle (save on verified login, remove on sign-out,
  onTokenRefresh re-persist), foreground SnackBar display, tap routing
  (`type`+`relatedId` → /chat/:id or /booking/:id, /home fallback).
- Known follow-ups (documented, not release-blocking for internal):
  real FCM delivery still needs the trusted backend (Cloud Functions +
  HTTP v1); the app consumes but does not yet send FCM.
- Booking price discrepancy (QA on device): service card showed K1300,
  booking review showed K1000.00 - booking_screen.dart uses
  `_provider!.basePrice`, not the service price. Needs a data/design
  decision, tracked for the next session.
- Credential hygiene: `seantinashenyakutira@gmail.com` password was
  shared in chat on 2026-10-17; recommend rotating it.

## Pre-submission gates

1. **Play Console version codes** — this build is 1.0.3+**5**;
   confirm Play's highest code < 5 before upload (owner's console).
   If 5 was consumed for another upload, rebuild:
   `gh workflow run "Build APK" -R drizzlysean/sangaso --ref recovery/unified-design-2026-10-17 -f build_number=<n+1>` and re-verify.
2. **Brand asset** — RESOLVED: authentic logo from the recovered
   website is now the app's branding (owner-ordered swap, commit
   `a97553b`). Launcher icon = `assets/images/app_icon.png` via
   flutter_launcher_icons (+ adaptive foreground/background).
3. **Firebase production config** — app uses `google-services.json` +
   `firebase_options.dart` defaults; no emulator leak (test-enforced).
4. **Internal testing track** — upload through the OWNER's browser
   session only. Never ask for or receive credentials in chat.

## Device QA without USB (Section 7 of the brief)

Wireless debugging (Android 11+), owner performs pairing locally:
1. Phone: Developer options → Wireless debugging → Pair device with
   pairing code (shows code + host:port).
2. Machine: `adb pair <host:port from the phone>` → owner types the
   one-time pairing code at the prompt (the code must never be pasted
   into chat).
3. `adb devices -l` confirm → `flutter devices` → run the app.
4. If behind same LAN: `adb connect <ip:port>`; for emulator ports:
   `adb reverse tcp:8080 tcp:8080` (+9099, +9199).
5. Fallback: install `build/app/outputs/flutter-apk/app-debug.apk`
   directly on the phone (email/Drive/USB file share) — the release AAB
   must NOT be distributed manually for testing; internal testing
   requires the Play bundle.

## Post-upload verification (truthful claims only)

- Check release status shows "In review/Ready" — do not call it "live"
  unless Play confirms it is serving.
- Do NOT promote to closed/public testing or production without the
  owner explicitly saying so.

## Website counterpart (coordination item, no action taken here)

The recovered website tree contains NO account-deletion request page.
Google Play account-deletion policy alternatives (web flow or email
route) still need the owner's decision; the in-app deletion path exists
now. The website tree was not modified.

## Session 5 addendum -- price-fix release candidate (2026-10-18)

| Item | Value |
| --- | --- |
| Source commit | run `39153033573`, head `e4a9037` (code at `9d217bb`) |
| Version | **1.0.3+6** (bumped from +5 so the superseded +5 can never collide on Play) |
| SHA-256 | `51d3b662afa5131ad1709ffd308b20bd92ca775aa5fa0e45e0f6f6cf4b08d2a7` |
| Size | 47,042,731 bytes |
| Signing / branding | UPLOAD.SF+RSA verified; logo_icon.png (55,631 B) byte-confirmed |
| Tests | 83/83 pass (was 79/79: +2 booking-service-linkage tests, +2 password-reset tests, +legacy-doc test, +2 lifecycle earlier), analyze 0 errors/0 warnings |

Superseded bundles (do NOT submit): all 1.0.3+4 builds, 1.0.2+3, and **1.0.3+5** (run `39121956994`, SHA `4a427b1a440b155d56a89ce159d257e353aaa9bbdf6870429bb7b01e80dc7954`, size 47,040,076 B).

Price mismatch root cause + fix (code commit `6a03c1a`):
- Root cause: the booking funnel dropped the selected service at
  Book Now (/book/:providerId carried only providerId). Bookings were
  created from the provider profile defaults - serviceType =
  provider.category, price = provider.basePrice (K1,000) - while the
  service card showed ServiceModel.price (K1,300). Not stale data, not
  formatting: a schema gap (BookingModel had no service reference).
- Correct amount: the tapped service price (the CTA is specific to
  that service).
- Fix: BookingModel gains nullable serviceId/serviceName (legacy docs
  read as null); BookingService persists them; Book Now appends
  serviceId as a route query param; BookingScreen loads the service
  from Firestore and books its price (fallback to provider starting
  price labeled honestly as "Starting price" if lookup fails).
- Regression tests: createBooking persists origin service + price;
  legacy bookings without service refs remain readable.

Password-reset defect fixed (commit `9d217bb`): the Forgot-password
dialog called FirebaseAuth directly, bypassing the AuthService seam;
now uses AuthService.resetPassword (covered by 2 new tests).

Truthful status of device QA: NOT re-run this session. The test phone
(USB Redmi, serial mjtkzp7h49onqkz5) stayed offline all session; the
previous attempt was disrupted by a YouTube picture-in-picture overlay
hijacking touches (plus WhatsApp/LarkPlayer focus shifts). Nothing was
sent from WhatsApp; media was paused. Unverified-on-device list:
photo upload flow, booking Confirm navigation, Google sign-in consent
dialog, notification tap routing, logout + account deletion.
