# Overnight App Recovery — Sangaso Flutter (Session B)

Date: Saturday 17 October 2026 (overnight run)
Owner account used for all remote operations: `drizzlysean` (verified via `gh api user`)

## Baseline and branch

- Repository: `https://github.com/drizzlysean/sangaso.git`
- Baseline SHA on `main` (last pushed, verified): `c09bb0d032a1176a8cb95f2eaeddde0f6ebe65e6`
  - Commit message: "Release: Flutter 3.38.5 toolchain, signed AAB job, restore modern Material APIs"
- Feature branch: `recovery/unified-design-2026-10-17` (created from baseline, pushed to origin)
- `main` untouched; no force-pushes performed.

## Toolchain installed on this PC (previous PC had none of it)

- Flutter stable 3.38.5 (Dart 3.10.4) → `C:\tools\flutter-sdk\flutter`
- Temurin JDK 17.0.20.1 (Android/Gradle builds) → `C:\tools\jdk17`
- Temurin JDK 21.0.12.1 (required by current firebase-tools for emulators) → `C:\tools\jdk21`
- Android SDK cmdline-tools + platform-tools + platforms;android-36 + build-tools;36.0.0 → `C:\tools\android-sdk`
- firebase-tools (global npm), Node v22, git portable already present.
- `gh` authenticated as `drizzlysean`; repo-local git credential helper routed through
  `gh auth git-credential` because Windows Credential Manager held a stale
  `seantinashenyakutira-whatsblade` token that caused 403 pushes. Local config only.

## Commits pushed (in order)

1. `90e1646` chore: restore recovery branch, remove obsolete stubs, tidy gitignore
2. `9784e49` fix: harden date parsing, friendly auth errors, category passthrough, verification seam, emulator mode
3. `8735737` feat: isolated local-test emulator harness (opt-in, demo-sangaso-local, NEVER DEPLOY rules)
4. `53a46db` feat: shared design tokens, Barlow/Playfair typography, branded widgets
5. `5752d16` feat: align welcome screen with shared design system
6. `8db38a1` feat: unify login and signup with shared design system
7. `4ed6cb5` feat: brand splash and verify-email surfaces
8. `714abad` feat: warm service cards and surfaces in search
9. `9356d6c` chore: bump version to 1.0.2+3 for Play release

All pushed to `origin/recovery/unified-design-2026-10-17` immediately after each milestone passed its checks.

## Reconstructed fixes (evidence-based)

- **Robust Firestore date parsing** (`lib/src/models/firestore_date.dart`, wired into booking,
  service, user, review, notification and message models): accepts `Timestamp`, `DateTime`,
  integer milliseconds (and small integers as epoch seconds), ISO-8601 strings and numeric
  strings. Required fields (e.g. `createdAt`, `scheduledTime`) now fail loudly with a
  `FormatException` naming the field instead of silently inventing values; optional fields
  (`acceptedAt`, `startedAt`, `completedAt`, user `createdAt`/`updatedAt`) keep null as null and
  also fail loudly on malformed non-null values. Evidence: the deleted obsolete stub
  `lib/models/user_model.dart` contained an old `_parseTimestamp` helper implementing exactly this
  lost approach (Milestones 1C–1E).
- **Friendly auth errors** (`lib/src/services/auth_errors.dart`): `FirebaseAuthException` codes map
  to plain-language messages; unknown codes return a safe fallback and raw exception payloads are
  never shown. Wired into login, signup, forgot-password dialog and verify-email screens.
- **Email-verification seam** (`lib/src/services/email_verification_service.dart`): Verify Email
  screen no longer touches `FirebaseAuth.instance` directly; production implementation injected in
  `main.dart`. Widget tests inject a fake — verified working.
- **Search/category passthrough and validated filter state**: home category tiles now navigate to
  `/search?category=<label>`; `SearchScreen` accepts `initialCategory`, validated against the
  shared taxonomy (`lib/src/core/constants/service_categories.dart`) with fallback to `'All'`.
  Home-only cats like `Repairs` / `Car Wash` correctly fall back to All.
- **Removed obsolete stubs**: `lib/services/auth_service.dart` (was literally "TODO Implement this
  library.") and `lib/models/user_model.dart` (partial duplicate) — zero importers, confirmed by
  grep before deletion.
- **Opt-in Firebase emulator mode** in `lib/main.dart`: `SANGASO_USE_EMULATORS=true`
  (`--dart-define` or env var) connects Auth 9099 / Firestore 8080 / Storage 9199. No automatic
  fallback; production Firebase is untouched when the flag is absent. All emulator tooling lives
  in `local-test/` only.
- Existing behaviors preserved: duplicate UI submission guards on auth screens, sign-in cache
  population, router role guards. No backend security claims are made from button guards.

## Tests replaced and passing

Stale `test/widget_test.dart` (referred to non-existent `MyApp()` and a counter) replaced with a
real smoke test of `SangasoApp` (shell boots and shows Welcome when signed out). New test suites:

- `test/models/firestore_date_test.dart` — parser behavior incl. loud failures
- `test/models/models_test.dart` — fromMap robustness for all five models (Timestamp, ISO string,
  int ms, epoch seconds, round-trips, loud failure on missing `createdAt`)
- `test/services/auth_errors_test.dart` — code mapping, no raw payload leaks, safe fallback
- `test/screens/login_screen_test.dart` — validation, friendly error display, seeker/admin
  navigation after success, password visibility toggle (fake AuthService, no Firebase)
- `test/screens/search_screen_test.dart` — initial render, text filtering, category chip stream
  switching, combined query+category state, invalid initial category fallback, empty state
- `test/screens/verify_email_screen_test.dart` — rendering with user email, manual recheck reload,
  cooldown-disabled resend, resend failure shows friendly message

`flutter test` result: **45 tests, all passing**. Plain `flutter test` contacts NO production
Firebase: fakes/seams cover every screen exercised, and the smoke test never initializes a real
Firebase app.

## Design alignment with the website (`SANGASO_SHARED_DESIGN_SYSTEM.md`)

- Tokens unified in `AppColors`/`AppTheme`: brand orange `#FF7043`, deep orange `#CF4F23`,
  soft orange `#FF8A5C`, tint `#FFF1EC`, charcoal `#171615`, elevated dark `#24221F`, warm ivory
  `#F7F4EE`, warm white `#FFFDF9`, dark text `#171717`, body `#5C5B57`, muted `#77736D`,
  light text `#FAF7F0`, hairline `#E7E0D6`. Existing alias names preserved so task screens keep
  compiling.
- Typography: Inter body/controls; Barlow Condensed 800 for display/hero headlines;
  Playfair Display italic accents (`DisplayHeading`), all via existing `google_fonts` dependency.
- New reusable widgets (`lib/src/core/widgets/brand.dart`): `PrimaryButton` (with trailing arrow,
  loading + pressed deep-orange states), `SecondaryButton`, `BrandLogoMark`, `SectionEyebrow`,
  `DisplayHeading`, `CharcoalPanel`, `BrandCard`, `ArrowLink`.
- Screens aligned: Welcome (removed the fake testimonial card entirely — no unverifiable content),
  Login, Signup, Splash (charcoal), Verify Email, Search service cards. How-it-works gets the same
  theme surfaces via tokens.
- Transitions kept at/under the 160–240 ms range; no continuous animations added. Routes, models,
  role behavior and form logic unchanged.
- Testimonials and unverifiable metrics are absent (shared-doc rule).

## Test / build command results

| Command | Result |
| --- | --- |
| `flutter pub get` | Dependencies resolve; prints Windows "symlink support / Developer Mode" warning. `.dart_tool/package_config.json` generated, builds work. Documented; OS settings NOT changed (needs owner approval). |
| `flutter test` | 45 passed, 0 failed |
| `flutter analyze` | 229 issues (baseline 256), **0 errors**. Remaining = deprecation infos (`withOpacity`), `prefer_const_*`, a few unused fields. Recorded honestly, not yet fixed. |
| `flutter build web` | SUCCESS (build\web) |
| `flutter build apk --debug` | SUCCESS (~20 min incl. CMake download) |
| `git diff --check` | clean |

## APK for physical device testing (debug only — NOT for Play)

- `build/app/outputs/flutter-apk/app-debug.apk` (local, untracked)
- `aapt dump badging`: package `com.sangaso.app`, versionCode 2, versionName 1.0.1, minSdk 24,
  targetSdk 36 (compileSdk 36 / Android 16)

## Emulator setup (Phase 2) — VERIFIED WORKING

- `local-test/firebase.json`: demo project `demo-sangaso-local`; Auth 9099, Firestore 8080,
  Storage 9199, Emulator UI 127.0.0.1:4000 only; `singleProjectMode`.
- `firestore.rules.emulator` / `storage.rules.emulator` intentionally permissive, marked
  **NEVER DEPLOY**.
- `node seed.js` — deterministic REST seed (3 services + 2 users), verified against the running
  emulator (no production contact, no admin credentials needed).
- Result: auth+firestore emulators started successfully on this PC with Temurin JDK 21.0.12
  (current firebase-tools refuses JDK < 21). Previous known Java loopback issues did not reproduce
  for startup/seed/UI endpoints.
- Production-isolation status: emulator mode is opt-in via `SANGASO_USE_EMULATORS=true` only.
  ALL tests run without the flag; no production Firebase was written or called by this session.

## Signed Play release (Phase 5)

- GitHub Actions `Build APK` workflow (manual dispatch) — both the debug-build job and the
  release job succeeded against this recovery branch, using the EXISTING upload-signing secrets
  (`UPLOAD_KEYSTORE_BASE64`, `UPLOAD_STORE_PASSWORD`, `UPLOAD_KEY_ALIAS`, `UPLOAD_KEY_PASSWORD`).
 .CREATED as [x] Signing secrets confirmed present in the repo; no values were read or printed.
- Release run: `39007126737` (workflow_dispatch, build_number=3) → artifact `sangaso-release-aab`
- Validated artifact (kept untracked in `artifacts/`):
  - File: `artifacts/app-release.aab`, 46,047,380 bytes
  - SHA-256: `DCA22173E55094D8748A5BA8556BE93E2C075A450EA459B740055C5D56BFE348`
  - `bundletool dump manifest`: package `com.sangaso.app`, versionCode **3**, versionName **1.0.2**,
    minSdk 24, targetSdk **36** (Android 16, meets the Aug 31 2026 Play policy)
  - Signature entries `META-INF/UPLOAD.SF` + `META-INF/UPLOAD.RSA` → signed with the existing
    upload key (no new keystore was ever created)
- Owner stated Play Console currently shows version 1.0.1; versionCode 3 > current pubspec/Play 2.\n  Owner chose: **prepare the AAB, do not upload yet.**
- Play Console status: bundle NOT uploaded and NOT accepted by Play Console yet — nothing is live.
  Uploading to the internal testing track remains deferred to the owner's authenticated session.

## Unresolved blockers / owner actions

1. **Upload the validated AAB to Play Console** (internal testing track) — requires owner's
   authenticated browser session. Everything is prepared and validated; do NOT use the debug APK
   for Play.
2. **Windows Developer Mode** decision: `flutter pub get` works but warns; enabling Developer
   Mode requires OS settings approval.
3. Remaining analyzer infos (~229, no errors) are honest deprecation/const style notes; cleanup
   is low-risk follow-up work, not release blocking.
4. Remaining authenticated screens (bookings, messaging, profile, admin) inherit the new tokens/
   theme automatically but were not individually restyled; recommend a follow-up pass.

## Bottom line

- Recovery branch pushed, all 45 tests green, 0 analyzer errors, web + debug APK + signed AAB all
  build successfully.
- The signed, validated `1.0.2+3` AAB targeting SDK 36 is ready for the owner to upload to the
  internal testing track; no Play Store release has happened, and nothing was published.
