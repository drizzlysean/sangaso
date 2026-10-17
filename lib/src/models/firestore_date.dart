import 'package:cloud_firestore/cloud_firestore.dart';

/// Robust Firestore date parsing.
///
/// Accepts Timestamp, DateTime, integer milliseconds (or integer seconds for
/// very small values), ISO-8601 strings, and numeric strings.
/// Required fields must fail loudly with a [FormatException] instead of
/// silently inventing values such as DateTime.now().
DateTime? tryParseFirestoreDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;

  if (value is num) {
    if (value <= 0) return null;
    // Epoch seconds are ~1.0e9 today, epoch milliseconds ~1.7e12.
    if (value < 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch((value * 1000).floor());
    }
    return DateTime.fromMillisecondsSinceEpoch(value.floor());
  }

  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final asInt = int.tryParse(trimmed);
    if (asInt != null) {
      if (asInt <= 0) return null;
      if (asInt < 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(asInt * 1000);
      }
      return DateTime.fromMillisecondsSinceEpoch(asInt);
    }

    return DateTime.tryParse(trimmed);
  }

  return null;
}

/// Parses a required date field. Fails loudly rather than inventing values.
DateTime parseFirestoreDate(dynamic value, {required String field}) {
  final parsed = tryParseFirestoreDate(value);
  if (parsed == null) {
    throw FormatException(
      'Invalid date for required field "$field": '
      '${value == null ? 'missing' : '${value.runtimeType} "$value"'}',
    );
  }
  return parsed;
}

/// Parses an optional date field. Null stays null; malformed non-null values
/// fail loudly instead of being silently discarded.
DateTime? parseFirestoreDateOrNull(dynamic value, {required String field}) {
  if (value == null) return null;
  final parsed = tryParseFirestoreDate(value);
  if (parsed == null) {
    throw FormatException(
      'Invalid date for optional field "$field": '
      '${value.runtimeType} "$value"',
    );
  }
  return parsed;
}
