# SANGASO APP STATE REPORT (for external review)
Date: 2026-10-18 · Author: build session notes · Target reader: an AI assistant helping plan release

---

## 1. Project snapshot

| Item | Value |
| --- | --- |
| Product | Sangaso — on-demand home-services marketplace in Zambia (seekers book local providers) |
| Platforms | Flutter app (Android primary), website www.sangaso.com (static SPA, separate repo) |
| Package name | `com.sangaso.app` |
| Current version | 1.0.3, versionCode 5 (build in hand) |
| Stack | Flutter 3.38.5, Dart, Firebase (Auth e-mail+Google, Firestore, Storage), Cloud Firestore data model |
| Repos | github.com/drizzlysean/sangaso (app in `app/`), working branch `recovery/unified-design-2026-10-17`. `main` untouched. |
| CI | GitHub Actions "Build APK" workflow: produces signed AAB + APK. Dispatched with `-f build_number=<n>` to pin versionCode. |
| Sign-off chain | Upload key signing on CI (`UPLOAD_KEYSTORE_BASE64` secret), Play App Signing on Play side |
| Owner | Sean (Google account: seantinashenyakutira@gmail.com) — owns Play Console, Firebase console, cPanel website. All console actions are owner-gated (agent never gets credentials). |

## 2. Release bundle in hand (verified 2026-10-18)

| Fact | Value |
| --- | --- |
| CI run | 39121956994 (head commit 107e763 on working branch) |
| File | app-release.aab |
| SHA-256 | 4a427b1a440b155d56a89ce159d257e353aaa9bbdf6870429bb7b01e80dc7954 |
| Size | 47,040,076 bytes |
| Package / versions | com.sangaso.app, versionName 1.0.3, versionCode 5 |
| minSdk / targetSdk | 24 / 36 (targetSdk 36 required by Play since Aug 2026) |
| Signing | `META-INF/UPLOAD.SF` + `UPLOAD.RSA` present = upload-key signed (not a new key) |
| Emulator safety | Release built WITHOUT emulator flag; a test asserts emulator mode is opt-in only |
| Branding | Authentic logo (recovered from the website repo) across app UI, launcher icon + adaptive layers + web/windows icons; asset byte-verified inside the AAB |
| Test battery before build | 79/79 tests pass, flutter analyze 0 errors / 0 warnings |

Superseded bundles (do NOT submit): versionCode 4 builds (run 39028406795 branded, run 39019071100 pre-branding) and 1.0.2+3 (run 39007126737).

Rationale for versionCode 5: no collision with any previously written 1.0.3+4 row on Play; strictly increasing counter.

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
| Search + service details + booking flow | PARTIALLY VERIFIED | Device-verified on earlier pass: search renders real services, details + 3-step booking form work; booking submission tap never re-confirmed will revisit |
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
- Booking confirmation tap issue from the previous session remains UNCONFIRMED (phone locked mid-test then; next session re-verify).

## 5. Known open items / bugs

1. **Booking price mismatch (REAL, needs decision)** — service card shows K1,300 but booking Review & Confirm shows K1,000 because booking_screen uses the provider's `basePrice` instead of that service's price. Either booking must use the right service price, or the design must be confirmed as intentional.
2. **One QA-written bio contains a typo** ("FastFast installs...") from the test-input method — cosmetic, fix in Edit Profile.
3. **"Skip for now" was removed from onboarding** — router forces completion; confirm the owner WANTS mandatory onboarding (it is safer for data quality, but is a product decision).
4. Booking submission tap → success navigation never re-confirmed on device.
5. No automated test of the photo-upload flow (image_picker + Firebase Storage) — verify manually first.
6. Play listing assets not prepared yet.

## 6. External blockers (coordinated, not code)

1. **LEGAL PAGES NOT LIVE (release blocker)**: live https://www.sangaso.com/?page=terms,+privacy,+delete-account all currently return the SPA landing page instead of legal content (identical 170kB landing body); /terms.php 404. The website source contains the multi-page routing patch, but it is NOT deployed (owner must deploy via their own cPanel/hosting session). Until it goes live the in-app legal links show wrong content — the Play submission "Privacy policy" field must not claim they work, and the description must avoid citing them as final.
2. **Google sign-in provider config**: Google provider must be enabled in Firebase Auth for the production app before upload (owner console action; SHA-1/SHA-256 of the upload key may need registering in the Firebase project settings).
3. **FCM real delivery** needs a small trusted backend (Cloud Function on booking/message writes calling HTTP v1) — requires the owner's authorization for billing; the app side is already consuming.
4. **Account deletion page** must go live together with the legal pages patch (Play account-deletion policy).

## 7. Credentials hygiene note

The owner's Gmail password was pasted in chat earlier (2026-10-17) — recommend rotating that Google account password and turning on 2FA. Agent sessions never request credentials; all console actions are performed by the owner.

## 8. Test accounts that exist in PRODUCTION Firebase

- seantinashenyakutira@gmail.com — real owner account (provider; "Steven kaunda"); keep
- rastaferi73@gmail.com (provider; device-loaded account) — temp QA account
- qa.seeker.1017@qateam.test — created in PRODUCTION by QA, unverified and unusable (fake domain); either delete from the users collection + Auth, or ignore as harmless

## 9. Ordered "what next" plan (for discussion)

Track A — unblock the WEBSITE (owner, one session):
1. Deploy the multi-page routing patch so ?page=terms|privacy|delete-account serve real content.
2. Verify each URL loads in a browser; then app-store legal links become true.

Track B — finish device QA (agent, after phone is reconnected):
1. Complete service photo upload (image picker → Firebase Storage) with a temp account.
2. Publish one real service listing; then seeker side: search → service detail → book → confirm booking → in-booking chat.
3. Re-verify the booking price behavior (bug item §5.1) and report the design decision to the owner.

Track C — Play submission (owner + agent):
1. Owner enables Google provider in Firebase (if Google sign-in is to be marketed), checks SHA keys.
2. Prepare store listing: description, feature graphic, 2-8 screenshots (capture from device), privacy policy URL (now-real), account deletion URL.
3. Owner uploads app-release.aab (SHA 4a427b…) to the Internal testing track, adds a tester e-mail list, rolls out.
4. Only after internal testing is green AND real FCM backend is wanted: owner approves a Cloud Function deployment; then closed testing (20+ testers, 14 days) in preparation for production.

Track D — small code follow-ups (agent, before submission):
1. Decide + fix the price mismatch (K1,300/K1,000).
2. Add a test for booking submission success path.
3. Optional: a smoke test for the image upload path.
4. Keep versionCode > 5 on any rebuild (`-f build_number=<n+1>` and re-verify SHA/signature before every upload).

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
