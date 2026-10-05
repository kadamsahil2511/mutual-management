import 'package:flutter_test/flutter_test.dart';
import 'package:mutual_management/core/calculations.dart';
import 'package:mutual_management/features/funds/fund_models.dart';

void main() {
  test('zero-return projection and target contribution use rupees', () {
    expect(futureValue(initial: 1000, monthly: 500, months: 12), 7000);
    expect(requiredMonthly(target: 7000, initial: 1000, months: 12), 500);
    expect(requiredMonthly(target: 900, initial: 1000, months: 12), 0);
    expect(futureValue(initial: 1000, monthly: 500, months: 0), 1000);
    expect(
      requiredMonthly(target: 1000, initial: 0, months: 0),
      double.infinity,
    );
  });

  test('effective annual compounding and inverse target formula agree', () {
    expect(
      futureValue(initial: 1000, monthly: 0, months: 12, annualReturn: 12),
      closeTo(1120, 0.000001),
    );
    final needed = requiredMonthly(
      target: 100000,
      initial: 10000,
      months: 36,
      annualReturn: 8,
    );
    expect(
      futureValue(initial: 10000, monthly: needed, months: 36, annualReturn: 8),
      closeTo(100000, 0.000001),
    );
    expect(
      () => futureValue(initial: 0, monthly: 1, months: 12, annualReturn: -100),
      throwsArgumentError,
    );
  });

  test('monthly clamp preserves original day through leap years', () {
    final start = DateTime(2024, 1, 31);
    expect(installmentDate(start, 0, 1), start);
    expect(installmentDate(start, 1, 1), DateTime(2024, 2, 29));
    expect(installmentDate(start, 2, 1), DateTime(2024, 3, 31));
    expect(installmentDate(start, 13, 1), DateTime(2025, 2, 28));
    expect(
      installmentDate(DateTime(2026, 11, 30), 1, 3),
      DateTime(2027, 2, 28),
    );
    expect(
      installmentDate(DateTime(2026, 11, 30), 2, 3),
      DateTime(2027, 5, 30),
    );
    expect(installmentId('sip-1', DateTime(2026, 2, 3)), 'sip-1_2026-02-03');
  });

  test('two purchases produce 65 units, 1560 value, and 60 gain', () {
    const firstAmountPaise = 100000;
    const secondAmountPaise = 50000;
    const firstNav = 20.0;
    const secondNav = 100.0 / 3;
    const latestNav = 24.0;
    const units =
        firstAmountPaise / 100 / firstNav + secondAmountPaise / 100 / secondNav;
    final valuePaise = (units * latestNav * 100).round();
    expect(units, 65);
    expect(valuePaise, 156000);
    expect(valuePaise - firstAmountPaise - secondAmountPaise, 6000);
  });

  test('overlap matches security IDs and preserves partial coverage', () {
    const a = [
      SecurityWeight(
        id: 'INE001',
        name: 'Company A',
        sector: 'Banks',
        weight: 10,
      ),
      SecurityWeight(
        id: 'INE002',
        name: 'Company B',
        sector: 'Power',
        weight: 20,
      ),
      SecurityWeight(
        id: 'INE001',
        name: 'Company A',
        sector: 'Banks',
        weight: 5,
      ),
    ];
    const b = [
      SecurityWeight(
        id: 'INE001',
        name: 'A Ltd renamed',
        sector: 'Banks',
        weight: 12,
      ),
      SecurityWeight(
        id: 'DIFFERENT_BOND',
        name: 'Company B',
        sector: 'Power',
        weight: 30,
      ),
    ];
    expect(overlapPercent(a, b), 12);
    expect(overlapPercent(b, a), 12);
    expect(overlapPercent(a, []), 0);
  });

  test(
    'sector allocation retains unknown assets and weights by portfolio value',
    () {
      final first = FundReference(
        schemeCode: 'a',
        name: 'A',
        amc: 'AMC',
        category: 'Equity',
        asOfDate: DateTime(2026),
        sourceUrl: 'https://example.test',
        holdings: const [
          SecurityWeight(id: 'A', name: 'A', sector: 'Banks', weight: 40),
          SecurityWeight(id: 'B', name: 'B', sector: 'Power', weight: 20),
        ],
      );
      final unknown = FundReference(
        schemeCode: 'b',
        name: 'B',
        amc: 'AMC',
        category: 'Debt',
        asOfDate: DateTime(2026),
        sourceUrl: 'https://example.test',
      );
      final sectors = sectorAllocation({first: 300, unknown: 100});
      expect(sectors['Banks'], 30);
      expect(sectors['Power'], 15);
      expect(sectors['Unavailable / unreported'], 55);
      expect(sectors.values.reduce((a, b) => a + b), 100);
      expect(sectorAllocation({first: 0}), isEmpty);
    },
  );
}
