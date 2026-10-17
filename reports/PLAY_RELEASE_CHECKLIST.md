# Play Release Checklist — internal testing (2026-10-17)

## Artifact facts (verify before every submission)

| Item | Value | How to re-verify |
| --- | --- | --- |
| Source commit (this build) | run `39019071100` dispatched on `recovery/unified-design-2026-10-17` (~`a070d7f`, run may tidy-commit nothing) | `gh run view 39019071100 --json headSha` |
| File | `app-release.aab` from artifact `sangaso-release-aab` | Actions page → artifacts |
| Package | `com.sangaso.app` | bundletool dump manifest |
| Version name / code | **1.0.3** / **4** | bundletool dump manifest; pubspec.yaml |
| minSdk / targetSdk | 24 / **36** (Android 16 — Play policy target since Aug 2026) | bundletool dump manifest |
| Signing | upload key (keystore from `UPLOAD_KEYSTORE_BASE64`), NOT a new key | `META-INF/UPLOAD.SF` + `UPLOAD.RSA` entries |
| Emulator safety | release built WITHOUT `--dart-define=SANGASO_USE_EMULATORS` | workflow yml contains no dart-define |

Re-verify commands on this machine (PowerShell):

```powershell
# hash
(Get-FileHash app-release.aab -Algorithm SHA256).Hash.ToLower()
# manifest (bundletool 1.18.3 at artifacts/)
java -jar artifacts\bundletool.jar dump manifest --bundle=app-release.aab
# test-tp for install on a device (optional)
java -jar artifacts\bundletool.jar build-apks --bundle=app-release.aab --output=temp.apks
```

The 1.0.2+3 AAB (SHA-256 `dca22173...fe348`, versionCode 3) is
SUPERSEDED — do not upload it; 1.0.3+4 includes onboarding, booking/
messaging/admin/deletion fixes and naming.

## Pre-submission gates

1. **Play Console version codes** — check the highest versionCode Play
   already has (owner's console). If 4 was previously consumed, rebuild:
   `gh workflow run "Build APK" -R drizzlysean/sangaso --ref recovery/unified-design-2026-10-17 -f build_number=<n+1>` and re-verify.
2. **Brand asset** — confirm or swap the logo placeholder before upload
   (owner decision; app icon = `assets/images/app_icon.png` via
   flutter_launcher_icons).
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
