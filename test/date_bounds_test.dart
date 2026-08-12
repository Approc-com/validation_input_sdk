import 'package:flutter_test/flutter_test.dart';
import 'package:validation_sdk/validation_sdk.dart';

void main() {
  test('parseBoundDate YYYY-MM-DD', () {
    final d = parseBoundDate('2036-08-12')!;
    expect(d, DateTime(2036, 8, 12));
  });

  test('min/max bounds', () {
    expect(isDateOnOrAfterMin(DateTime(2026, 8, 12), '2026-08-12'), isTrue);
    expect(isDateOnOrAfterMin(DateTime(2026, 8, 11), '2026-08-12'), isFalse);
    expect(isDateOnOrBeforeMax(DateTime(2036, 8, 12), '2036-08-12'), isTrue);
    expect(isDateOnOrBeforeMax(DateTime(2036, 8, 13), '2036-08-12'), isFalse);
  });
}
