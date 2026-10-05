import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutual_management/features/plans/user_models.dart';

void main() {
  test('goal uses integer paise and a portable calendar date', () {
    final goal = Goal(
      id: 'home',
      name: 'Home deposit',
      targetPaise: 125005099,
      targetDate: DateTime(2032, 2, 29, 18, 30),
      assumedAnnualReturn: 7.5,
    );
    final stored = goal.toMap();
    expect(stored['targetPaise'], 125005099);
    expect(stored['targetDate'], Timestamp.fromDate(DateTime.utc(2032, 2, 29)));
    expect(stored.containsKey('id'), isFalse);
    final restored = Goal.fromMap('home', stored);
    expect(restored.id, 'home');
    expect(restored.name, 'Home deposit');
    expect(restored.targetDate, DateTime(2032, 2, 29));
    expect(restored.assumedAnnualReturn, 7.5);
  });

  test('SIP round trip retains schedule, cancellation, and optional goal', () {
    final stored = Sip(
      id: 'sip-a',
      schemeCode: '118955',
      amountPaise: 250050,
      startDate: DateTime(2026, 1, 31),
      intervalMonths: 3,
      goalId: 'home',
      isActive: false,
    ).toMap();
    expect(stored['startDate'], Timestamp.fromDate(DateTime.utc(2026, 1, 31)));
    final restored = Sip.fromMap('sip-a', stored);
    expect(restored.amountPaise, 250050);
    expect(restored.intervalMonths, 3);
    expect(restored.goalId, 'home');
    expect(restored.isActive, isFalse);
    expect(restored.startDate, DateTime(2026, 1, 31));
  });

  test('unassociated records explicitly serialize null associations', () {
    expect(
      Sip(
        id: 'a',
        schemeCode: '118955',
        amountPaise: 100,
        startDate: DateTime(2026, 1, 1),
      ).toMap(),
      containsPair('goalId', null),
    );
    final contribution = Contribution(
      id: 'once',
      schemeCode: '118955',
      amountPaise: 12345,
      units: 6.1725,
      nav: 20,
      navDate: DateTime(2026, 1, 1),
      effectiveDate: DateTime(2026, 1, 2),
    ).toMap();
    expect(contribution, containsPair('sipId', null));
    expect(contribution, containsPair('goalId', null));
  });

  test('contribution preserves historical NAV and fractional units', () {
    final contribution = Contribution.fromMap('sip-a_2026-02-28', {
      'schemeCode': '118955',
      'amountPaise': 50000,
      'units': 20,
      'nav': 25,
      'navDate': Timestamp.fromDate(DateTime.utc(2026, 2, 27)),
      'effectiveDate': Timestamp.fromDate(DateTime.utc(2026, 2, 28)),
      'sipId': 'sip-a',
      'goalId': 'home',
    });
    expect(contribution.units, 20.0);
    expect(contribution.nav, 25.0);
    expect(contribution.amountPaise, 50000);
    expect(contribution.navDate, DateTime(2026, 2, 27));
    expect(contribution.effectiveDate, DateTime(2026, 2, 28));
    expect(contribution.sipId, 'sip-a');
    expect(contribution.goalId, 'home');
    expect(
      contribution.toMap()['navDate'],
      Timestamp.fromDate(DateTime.utc(2026, 2, 27)),
    );
  });

  test('malformed monetary amounts never silently round to paise', () {
    expect(
      () => Goal.fromMap('bad', {
        'name': 'Invalid',
        'targetPaise': 100.5,
        'targetDate': Timestamp.fromDate(DateTime.utc(2030)),
        'assumedAnnualReturn': 0,
      }),
      throwsA(isA<TypeError>()),
    );
  });
}
