# Play Release Checklist — internal testing (2026-10-17)

## Artifact facts (verify before every submission)

| Item | Value | How to re-verify |
| --- | --- | --- |
| Source commit (this build) | run `39028406795`, branch `recovery/unified-design-2026-10-17`, head `a97553b` (includes authentic branding) | `gh run view 39028406795 -R drizzlysean/sangaso --json headSha` |
| File | `app-release.aab` from artifact `sangaso-release-aab` (kept in untracked `artifacts/`) | Actions page → artifacts |
| SHA-256 | `a1be34b116692c974ba88c783509637dfe135e853848650f4ecb659b4ce1b7e5` | `(Get-FileHash artifacts\app-release.aab -Algorithm SHA256).Hash.ToLower()` |
| Size | 46,387,694 bytes | file properties |
| Package | `com.sangaso.app` | bundletool dump manifest |
| Version name / code | **1.0.3** / **4** | bundletool dump manifest; pubspec.yaml |
| minSdk / targetSdk | 24 / **36** (Android 16 — Play policy target since Aug 2026) | bundletool dump manifest |
| Signing | upload key (keystore from `UPLOAD_KEYSTORE_BASE64`), NOT a new key | `META-INF/UPLOAD.SF` + `UPLOAD.RSA` entries verified |
| Emulator safety | release built WITHOUT `--dart-define=SANGASO_USE_EMULATORS` | workflow yml contains no dart-define; `useEmulators` off by test |
| Branding | authentic logo; preserved original at `brand/logo-source.png`; regenerated `logo_icon.png`, `app_icon.png` + adaptive layers + web/windows icons; new asset sizes confirmed inside the AAB | zip listing of app-release.aab |

Re-verify commands on this machine (PowerShell):

```powershell
# hash
(Get-FileHash app-release.aab -Algorithm SHA256).Hash.ToLower()
# manifest (bundletool 1.18.3 at artifacts/)
java -jar artifacts\bundletool.jar dump manifest --bundle=app-release.aab
# test-tp for install on a device (optional)
java -jar artifacts\bundletool.jar build-apks --bundle=app-release.aab --output=temp.apks
```

Superseded artifacts (do NOT submit — placeholder branding):
- `1.0.2+3`, run `39007126737`, SHA-256 `dca22173e55094d8748a5ba8556be93e2c075a450ea459b740055c5d56bfe348`
- `1.0.3+4` pre-branding, run `39019071100`, SHA-256 `b012bca420debb79dc80d2f1f3a8fee191dc4672177e844c427d9bd9de26a637`

## Pre-submission gates

1. **Play Console version codes** — check the highest versionCode Play
   already has (owner's console). If 4 was previously consumed, rebuild:
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
