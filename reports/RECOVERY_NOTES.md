# App recovery notes (2026-10-17)

- Baseline SHA on `main`: `c09bb0d032a1176a8cb95f2eaeddde0f6ebe65e6`.
- Recovery branch: `recovery/unified-design-2026-10-17`.
- Toolchain on this PC: Flutter 3.38.5 (Dart 3.10.4), JDK 17.0.20.1, Android cmdline-tools with
  platform-tools, platforms;android-36, build-tools;36.0.0. All local installs.
- `flutter pub get` prints the Windows "building with plugins requires symlink support" /
  Developer Mode message, but dependency resolution succeeds (`.dart_tool/package_config.json`
  is generated, generated_plugins.cmake updated). Documented, not yet owner-approved to change
  OS settings.
- Baseline `flutter analyze`: 256 issues, 1 error (stale `test/widget_test.dart` referring to
  `MyApp()`), rest warnings/info (deprecations, const, unused).
- Removed obsolete no-importer stubs: `lib/services/auth_service.dart`,
  `lib/models/user_model.dart`. The deleted `lib/models/user_model.dart` stub contained an old
  `_parseTimestamp` helper confirming the lost Milestone 1C-1E approach to robust Firestore
  date parsing (Timestamp / ISO string / int / null handling) — reconstructed properly in this
  branch.
- Production Firebase config is NOT touched by emulator work; emulator mode is opt-in only.
