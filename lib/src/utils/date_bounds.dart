/// Parses validation.json `min_date` / `max_date` as `YYYY-MM-DD` (date-only).
DateTime? parseBoundDate(String? raw) {
  if (raw == null) return null;
  final text = raw.trim();
  if (text.isEmpty) return null;

  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
  if (m != null) {
    return DateTime(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
  }
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// True when [date] is on/after [minDate] (or [minDate] is unset/invalid).
bool isDateOnOrAfterMin(DateTime date, String? minDate) {
  final bound = parseBoundDate(minDate);
  if (bound == null) return true;
  return !_dateOnly(date).isBefore(bound);
}

/// True when [date] is on/before [maxDate] (or [maxDate] is unset/invalid).
bool isDateOnOrBeforeMax(DateTime date, String? maxDate) {
  final bound = parseBoundDate(maxDate);
  if (bound == null) return true;
  return !_dateOnly(date).isAfter(bound);
}