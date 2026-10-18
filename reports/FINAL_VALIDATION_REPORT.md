# Final Validation Report — final session (2026-10-17)

Branch: `recovery/unified-design-2026-10-17`, HEAD `a070d7f` at report time
(all commits pushed). Version: `1.0.3+4`.

## R1 — Release baseline (Section 3 of the brief)

| Command | Result |
| --- | --- |
| git status / branch / identity | clean tree; branch exists and is up to date with origin; pushes authenticated as `drizzlysean` through repo-local gh credential helper |
| flutter --version | 3.38.5 stable / Dart 3.10.4 |
| flutter pub get | resolves (Windows Developer-Mode symlink warning documented; requires owner OS-level decision) |
| flutter test | **69/69 pass** (45 before this session) |
| flutter analyze | **0 errors, 0 warnings**, 220 informational lints |
| flutter build web | success |
| flutter build apk --debug | success; aapt: `com.sangaso.app` versionCode **4** versionName **1.0.3**, minSdk 24, targetSdk 36 |
| git diff --check | clean |

## R2 — Critical functional validation (Section 5 of the brief)

Validated as committed unit tests using `fake_cloud_firestore` +
`firebase_auth_mocks` (fakes, no production calls). Truthful scope:
service/business logic is validated end-to-end at the data layer;
interactive UI runs on a real device are pending the owner's phone.

1. **Booking creation** — contact info stamped from both parties,
   notification written for the provider (`booking_service_test.dart`).
2. **Booking duplicate prevention** — identical retry (same seeker,
   provider, UTC slot, address) returns the SAME booking id, creates ONE
   booking, sends ONE notification; terminal-state requests allow rebooking
   (`createBooking` idempotency fingerprint, RFC-4122 URL-namespace uuidv5).
3. **State transitions** — accepted/inProgress/completed write
   `acceptedAt`/`startedAt`/`completedAt` and notify the seeker with the
   right types; unknown booking id is a no-op.
4. **Messaging** — message doc stamped with senderId/bookingId/timestamp;
   recipient (the OTHER party) receives one notification; sender who is
   not a participant (stranger id) is rejected with
   `SenderNotAllowedException` and nothing is written; empty text without
   an image rejected; missing booking rejected.
5. **Notifications** — created on booking request + every status change +
   new message (all asserted); unread/read dot behavior is the screen's
   `isRead` state (no fake read-state claims).
6. **Reviews** — one review per booking enforced; ratings outside 1–5
   rejected BEFORE write; average rating is per-provider.
7. **Admin** — platform stats (users/providers/seekers/verified/pending
   KYC/bookings/revenue) computed correctly; approve/reject KYC mutate
   isVerified + reason fields as documented; ban/unban works; search is
   case-insensitive over displayName/email/tradingName.
8. **Account deletion** — wrong password → NOTHING deleted (auth
   exception surfaces), re-auth → owned services + profile doc deleted +
   Firebase Auth account deleted NOW; results truthfully list remaining
   record types (chats, past bookings, reviews) that only a backend
   cascade can purge.
9. **Date parsing** — existing `firestore_date_test.dart` suite still
   green (Timestamp/DateTime/int-ms/ISO-8601/format-error naming).
10. **Emulator gate** — `useEmulators` defaults OFF and is web-safe
    (dart:io env lookup no longer reachable on web → the web production
    build cannot crash at boot and cannot reach emulator ports).

## R3 — What was NOT validated (debt, not a pass)

- Interactive runs on real Android hardware (Section 7 of the brief) are
  pending: no device was attached to this machine during the session
  (`adb devices` empty). Wireless pairing instructions are in
  PLAY_RELEASE_CHECKLIST.md for the owner.
- Push notifications (FCM tokens) and Storage image uploads were not
  exercised end-to-end in this session.
- The production Firestore security rules live in the Google console and
  are not in-repo; client-side guards were added, but the platform rules
  should be audited/reported in the console once the owner reviews them.

## R4 — Reports index

- `OVERNIGHT_APP_RECOVERY.md` — recovery + session 2 log
- `FLUTTER_UI_INTEGRATION_RESULTS.md` — UI/design alignment evidence
- `LOCAL_FIREBASE_EMULATOR_GUIDE.md` — exact machine paths + commands
- `PLAY_RELEASE_CHECKLIST.md` — release/submission facts

## Session 3 addendum -- authentic branding (2026-10-17, commit a97553b)

Owner ordered the placeholder-logo replacement with the authentic
website logo after this report was written. Re-validated post-swap:
pub get OK, 69/69 tests pass, analyze 0 errors / 0 warnings (220 infos),
app-debug.apk 605.7s build OK (aapt: com.sangaso.app 4 / 1.0.3).
Launcher icons + adaptive layers + favicon/web/windows icons regenerated
from the preserved master (brand\logo-source.png).

New verified release artifact (supersedes the row in R3): CI run
39028406795, commit a97553b, app-release.aab 46,387,694 B, SHA-256
a1be34b116692c974ba88c783509637dfe135e853848650f4ecb659b4ce1b7e5,
com.sangaso.app 1.0.3 (4), minSdk 24 / targetSdk 36, UPLOAD-signed.
Branding assets byte-verified inside the bundle. Play upload remains
owner-gated until the branding is confirmed.

## Session 4 addendum -- FINAL POLISH + release rebuild (2026-10-18, commits 29c005a / 107e763)

Owner-ordered polish before Play upload. All completed (see
PLAY_RELEASE_CHECKLIST.md "Final-polish record"):

- Rebuilt bundle: CI run 39121956994, commit 107e763 (head), version
  1.0.3+5 (versionCode bumped past the branded +4 so an already-written
  artifact row can never collide on Play). app-release.aab
  47,040,076 B, SHA-256
  4a427b1a440b155d56a89ce159d257e353aaa9bbdf6870429bb7b01e80dc7954,
  package com.sangaso.app, minSdk 24 / targetSdk 36,
  META-INF/UPLOAD.SF+RSA (upload key), branding asset byte-verified
  (base/assets/flutter_assets/assets/images/logo_icon.png, 55,631 B).
  This supersedes 1.0.3+4 runs 39028406795 and 39019071100.
- Tests: 79/79 pass (was 69; +10 new lifecycle/consent/onboarding tests
  in test/lifecycle_test.dart). Analyze: 0 errors, 0 warnings.
- Router redirect hardening: null-safe completion check + loop guard
  for the profile-setup redirect.
- Consent gate (signup + login, email and Google paths), Google
  two-phase sign-in, multi-step onboarding with heardAbout (seeker),
  FCM token lifecycle + foreground display + tap routing wired in
  app.dart state (permission requested post-verified-login).

Unresolved, truthfully stated:
1. LEGAL PAGES NOT LIVE: https://www.sangaso.com/?page=terms|privacy|
   delete-account all return the SPA landing page (identical 170,622 B
   body, no legal content); /terms.php 404. The website multi-page
   patch is NOT deployed (website session owns deploy). Until it is,
   in-app legal links lead to the wrong content. Coordinated release
   blocker - do not describe the links as working in store listing.
2. FCM end-to-end delivery still requires a trusted backend (owner-
   gated; app side is ready to consume).
3. Booking review price uses provider basePrice (K1000) while the
   service card showed K1300 - flag for owner decision.
4. Device QA paused mid-flow (owner request); booking Confirm tap
   navigation never re-verified after screen rotation/lock issues.
   Redmi (USB, mjtkzp7h49onqkz5) available for the next QA pass.
5. Owner login password appeared in chat (2026-10-17). Recommend
   rotating that Google account password.
