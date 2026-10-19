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
