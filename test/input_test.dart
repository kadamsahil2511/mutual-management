import 'package:flutter_test/flutter_test.dart';
import 'package:mutual_management/core/input.dart';

void main() {
  test(
    'money parses exact paise and rejects exponent, sign, excess decimals',
    () {
      expect(parsePaise('1000'), 100000);
      expect(parsePaise('10.05'), 1005);
      expect(parsePaise('0.01'), 1);
      for (final bad in ['-10', '0', '1e5', 'NaN', '10.005', '1,000', '']) {
        expect(parsePaise(bad), isNull, reason: bad);
      }
    },
  );
  test('auth return paths remain within app', () {
    expect(
      safeNextPath('/portfolio?invest=118955'),
      '/portfolio?invest=118955',
    );
    for (final bad in [
      'https://evil.test',
      '//evil.test',
      '/auth',
      '/unknown',
      '',
    ]) {
      expect(safeNextPath(bad), '/');
    }
  });
  test('email validation trims but requires a domain', () {
    expect(emailError(' person@example.com '), isNull);
    expect(emailError('person@'), isNotNull);
    expect(emailError(''), isNotNull);
  });
}
