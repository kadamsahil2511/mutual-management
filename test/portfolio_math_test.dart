import 'package:flutter_test/flutter_test.dart';
import 'package:mutual_management/features/plans/user_models.dart';
import 'package:mutual_management/features/portfolio/portfolio_math.dart';

Contribution purchase(String id, int amount, double nav) => Contribution(
  id: id,
  schemeCode: '118955',
  amountPaise: amount,
  units: amount / 100 / nav,
  nav: nav,
  navDate: DateTime(2026, 1, 1),
  effectiveDate: DateTime(2026, 1, 1),
);
void main() {
  test(
    'derive holdings from immutable contributions, then value at latest NAV',
    () {
      final holding = deriveHoldings(
        [purchase('one', 100000, 25), purchase('two', 50000, 20)],
        {'118955': 24},
      ).single;
      expect(holding.units, 65);
      expect(holding.investedPaise, 150000);
      expect(holding.value, 1560);
      expect(holding.gain, 60);
    },
  );
  test('unavailable NAV never substitutes cost as market value', () {
    final holding = deriveHoldings([purchase('one', 100000, 25)], {}).single;
    expect(holding.investedPaise, 100000);
    expect(holding.value, isNull);
    expect(holding.gain, isNull);
  });
}
