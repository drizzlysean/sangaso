import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sangaso/src/models/firestore_date.dart';

void main() {
  group('tryParseFirestoreDate', () {
    test('parses Firestore Timestamp', () {
      final date = DateTime.utc(2026, 1, 15, 10, 30);
      final parsed = tryParseFirestoreDate(Timestamp.fromDate(date));
      expect(parsed!.toUtc(), date);
    });

    test('passes DateTime through', () {
      final date = DateTime(2025, 6, 1);
      expect(tryParseFirestoreDate(date), date);
    });

    test('parses integer milliseconds', () {
      const ms = 1767225000000; // 2026-01-01T01:10:00.000Z
      final parsed = tryParseFirestoreDate(ms);
      expect(parsed!.toUtc().millisecondsSinceEpoch, ms);
    });

    test('parses numeric strings as milliseconds', () {
      const ms = 1767225000000;
      final parsed = tryParseFirestoreDate('$ms');
      expect(parsed!.toUtc().millisecondsSinceEpoch, ms);
    });

    test('parses small integers as epoch seconds', () {
      const seconds = 1767225000;
      final parsed = tryParseFirestoreDate(seconds);
      expect(parsed!.toUtc().millisecondsSinceEpoch, seconds * 1000);
    });

    test('parses ISO-8601 strings', () {
      final parsed = tryParseFirestoreDate('2026-01-15T10:30:00.000Z');
      expect(parsed!.toUtc().millisecondsSinceEpoch,
          DateTime.utc(2026, 1, 15, 10, 30).millisecondsSinceEpoch);
    });

    test('returns null for null, empty, zero and unparseable values', () {
      expect(tryParseFirestoreDate(null), isNull);
      expect(tryParseFirestoreDate(''), isNull);
      expect(tryParseFirestoreDate('   '), isNull);
      expect(tryParseFirestoreDate(0), isNull);
      expect(tryParseFirestoreDate(-5), isNull);
      expect(tryParseFirestoreDate('not-a-date'), isNull);
      expect(tryParseFirestoreDate(false), isNull);
    });
  });

  group('parseFirestoreDate (required)', () {
    test('returns parsed date for valid values', () {
      expect(parseFirestoreDate(Timestamp.now(), field: 'createdAt'), isA<DateTime>());
    });

    test('throws FormatException for missing value', () {
      expect(
        () => parseFirestoreDate(null, field: 'createdAt'),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('createdAt'),
        )),
      );
    });

    test('throws FormatException for garbage value', () {
      expect(
        () => parseFirestoreDate('garbage', field: 'scheduledTime'),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('scheduledTime'),
        )),
      );
    });
  });

  group('parseFirestoreDateOrNull (optional)', () {
    test('keeps null as null', () {
      expect(parseFirestoreDateOrNull(null, field: 'acceptedAt'), isNull);
    });

    test('parses valid values', () {
      expect(parseFirestoreDateOrNull(1767225000000, field: 'acceptedAt'), isNotNull);
      expect(parseFirestoreDateOrNull(Timestamp.now(), field: 'acceptedAt'), isNotNull);
    });

    test('throws FormatException for malformed non-null values', () {
      expect(
        () => parseFirestoreDateOrNull('oops', field: 'completedAt'),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('completedAt'),
        )),
      );
    });
  });
}
