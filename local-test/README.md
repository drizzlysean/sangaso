# Sangaso local emulator test harness

Isolated, opt-in Firebase emulator environment for local automated checks.
Production Firebase is never contacted by this folder.

## Fixed parameters
- Explicit project id: `demo-sangaso-local`
- Auth emulator: `localhost:9099`
- Firestore emulator: `localhost:8080`
- Storage emulator: `localhost:9199`
- Emulator UI (localhost only): http://127.0.0.1:4000
- Rules files are intentionally permissive and marked NEVER DEPLOY.

## How to use
Requirements: Node 20+ and a JDK 21+ on PATH (current firebase-tools refuses
older JDKs). Android/Gradle builds elsewhere use JDK 17 — set Java 21 only for
the emulator shell.

```powershell
cd local-test
npm install
set "JAVA_HOME=C:\path\to\jdk-21"
firebase emulators:start --project demo-sangaso-local
node seed.js   # deterministic REST seed: 3 services + 2 demo users
```
Verified on this PC (17 Oct 2026): auth 9099 + firestore 8080 started
successfully with Temurin JDK 21.0.12; seed REST round-trips confirmed.

Then run the app in emulator mode (explicit, no fallback):
```powershell
flutter run --dart-define=SANGASO_USE_EMULATORS=true
```
or set the environment variable `SANGASO_USE_EMULATORS=true` before launching.
Without the flag, the app never touches these endpoints and there is no
automatic fallback.

## SDK check
```powershell
firebase emulators:exec --project demo-sangaso-local "node seed.js"
```
