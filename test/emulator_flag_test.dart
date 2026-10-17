import 'package:flutter_test/flutter_test.dart';
import 'package:sangaso/main.dart';

void main() {
  test('useEmulators defaults to OFF without the opt-in flag or env variable',
      () {
    // Regression guard: emulator mode must never enable itself.
    expect(useEmulators, isFalse,
        reason:
            'SANGASO_USE_EMULATORS must be opted into explicitly; a default '
            'of false keeps production Firebase untouched.');
  });
}
