# Local Firebase Emulator Guide (Windows, this machine)

Purpose: run the Android app against a LOCAL, disposable Firebase only.
Production Firebase is never touched — the app's emulator mode is opt-in
and there is no automatic production fallback (guarded by a regression
test `test/emulator_flag_test.dart`).

## Prerequisites on this machine

| Tool | Path | Notes |
| --- | --- | --- |
| Flutter 3.38.5 | `C:\tools\flutter-sdk\flutter` | Dart 3.10.4 |
| JDK 17 | `C:\tools\jdk17` (jdk-17.0.20.1+1) | Gradle/Android builds |
| JDK 21 | `C:\tools\jdk21` | REQUIRED by firebase-tools runtime |
| Android SDK | `C:\tools\android-sdk` | platform-tools, platforms;android-36, build-tools;36.0.0 |
| firebase-tools | `C:\nvm4w\nodejs\firebase.cmd` | global npm install |

Session bootstrap (PowerShell):

```powershell
$env:PATH      = "C:\tools\flutter-sdk\flutter\bin;C:\tools\jdk17\jdk-17.0.20.1+1\bin;$env:PATH"
$env:ANDROID_SDK_ROOT = "C:\tools\android-sdk"
$env:JAVA_HOME = "C:\tools\jdk17\jdk-17.0.20.1+1"
```

## 1. Start the emulators

```powershell
cd app\local-test
$env:JAVA_HOME = "C:\tools\jdk21";
$env:PATH = "C:\tools\jdk21\bin;$env:PATH"
Start-Process -FilePath "cmd.exe" -ArgumentList '/c',
  'set "JAVA_HOME=C:\tools\jdk21" && set "PATH=C:\tools\jdk21\bin;%PATH%" && "C:\nvm4w\nodejs\firebase.cmd" emulators:start > emu_bg.log 2>&1'
```

Emulator URLs: Auth 127.0.0.1:9099 · Firestore 127.0.0.1:8080 ·
Storage 127.0.0.1:9199 · UI http://127.0.0.1:4000

## 2. Seed demo data

Demo project id: `demo-sangaso-local`.

```powershell
node seed.js   # REST-based; <3s; creates 3 services + 2 users
```

The admin-SDK approach HANGS on credential lookup on this machine — use
the verified REST seed; never look somewhere else when things work.

## 3. Run/launch the app against the emulators

Mobile/desktop (env var path):

```powershell
flutter run --dart-define=SANGASO_USE_EMULATORS=true
```

Web (dart-define only; the env var path is intentionally unreachable on
web to avoid a dart:io crash):

```powershell
flutter run -d edge --dart-define=SANGASO_USE_EMULATORS=true
```

On an Android emulator device, `localhost` inside the emulator is the
emulator itself: map it first with:

```powershell
C:\tools\android-sdk\platform-tools\adb.exe reverse tcp:8080 tcp:8080
C:\tools\android-sdk\platform-tools\adb.exe reverse tcp:9099 tcp:9099
C:\tools\android-sdk\platform-tools\adb.exe reverse tcp:9199 tcp:9199
```

## 4. What NOT to do

- NEVER deploy `local-test/firestore.rules.emulator` or
  `local-test/storage.rules.emulator` — they are permissive on purpose
  and marked NEVER DEPLOY.
- Never leave emulator mode enabled in a release: release builds must be
  produced without `--dart-define` (verified: release flag is absent and
  `useEmulators` tests as false by default).

## 5. Truthful status of emulator-verified flows this session

Unit-level validations against `fake_cloud_firestore`/
`firebase_auth_mocks` (fast, repeatable, and committed to the repo as
tests) cover: booking create/idempotency/status transitions/notifications,
messaging sender-identity guard, review dedupe + bounds + averages, admin
stats/KYC/search, account deletion (re-auth, doc + owned services + auth
record removal, leftovers reported). The interactive emulator app run was
NOT exercised on a device this session (see FINAL_VALIDATION_REPORT.md
limitations).
