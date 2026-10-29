import 'package:intl/intl.dart';

/// Converts timestamps between UTC storage and the device's local display time.
class KintaTime {
  KintaTime._();

  static DateTime? parseUtc(Object? value, {bool assumeLocalWhenUnmarked = false}) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    final normalized = text.contains('T') ? text : text.replaceFirst(' ', 'T');
    final hasTimezone = RegExp(r'(?:Z|[+-]\d{2}:?\d{2})$', caseSensitive: false).hasMatch(normalized);
    try {
      if (!hasTimezone && assumeLocalWhenUnmarked) return DateTime.parse(normalized).toUtc();
      return DateTime.parse(hasTimezone ? normalized : '${normalized}Z').toUtc();
    } on FormatException {
      return null;
    }
  }

  static String? toUtcIso(Object? value, {bool assumeLocalWhenUnmarked = false}) =>
      parseUtc(value, assumeLocalWhenUnmarked: assumeLocalWhenUnmarked)?.toIso8601String();

  static String formatLocal(Object? value, {String pattern = 'yyyy-MM-dd hh:mm a', String empty = '-', bool assumeLocalWhenUnmarked = false}) {
    final timestamp = parseUtc(value, assumeLocalWhenUnmarked: assumeLocalWhenUnmarked);
    return timestamp == null ? empty : DateFormat(pattern).format(timestamp.toLocal());
  }
}
