import 'package:cloud_firestore/cloud_firestore.dart';

// These are calendar dates, not instants. UTC midnight keeps a selected date
// stable when the same account opens the app in another time zone.
Timestamp _storeDate(DateTime date) =>
    Timestamp.fromDate(DateTime.utc(date.year, date.month, date.day));

DateTime _readDate(Object? value) {
  final date = (value as Timestamp).toDate().toUtc();
  return DateTime(date.year, date.month, date.day);
}

class Goal {
  const Goal({
    required this.id,
    required this.name,
    required this.targetPaise,
    required this.targetDate,
    this.assumedAnnualReturn = 0,
  });
  final String id;
  final String name;
  final int targetPaise;
  final DateTime targetDate;
  final double assumedAnnualReturn;
  factory Goal.fromMap(String id, Map<String, dynamic> map) => Goal(
    id: id,
    name: map['name'] as String,
    targetPaise: map['targetPaise'] as int,
    targetDate: _readDate(map['targetDate']),
    assumedAnnualReturn: (map['assumedAnnualReturn'] as num).toDouble(),
  );
  Map<String, dynamic> toMap() => {
    'name': name,
    'targetPaise': targetPaise,
    'targetDate': _storeDate(targetDate),
    'assumedAnnualReturn': assumedAnnualReturn,
  };
}

class Sip {
  const Sip({
    required this.id,
    required this.schemeCode,
    required this.amountPaise,
    required this.startDate,
    this.intervalMonths = 1,
    this.goalId,
    this.isActive = true,
  });
  final String id;
  final String schemeCode;
  final int amountPaise;
  final DateTime startDate;
  final int intervalMonths;
  final String? goalId;
  final bool isActive;
  factory Sip.fromMap(String id, Map<String, dynamic> map) => Sip(
    id: id,
    schemeCode: map['schemeCode'] as String,
    amountPaise: map['amountPaise'] as int,
    startDate: _readDate(map['startDate']),
    intervalMonths: map['intervalMonths'] as int,
    goalId: map['goalId'] as String?,
    isActive: map['isActive'] as bool,
  );
  Map<String, dynamic> toMap() => {
    'schemeCode': schemeCode,
    'amountPaise': amountPaise,
    'startDate': _storeDate(startDate),
    'intervalMonths': intervalMonths,
    'goalId': goalId,
    'isActive': isActive,
  };
}

class Contribution {
  const Contribution({
    required this.id,
    required this.schemeCode,
    required this.amountPaise,
    required this.units,
    required this.nav,
    required this.navDate,
    required this.effectiveDate,
    this.sipId,
    this.goalId,
  });
  final String id;
  final String schemeCode;
  final int amountPaise;
  final double units;
  final double nav;
  final DateTime navDate;
  final DateTime effectiveDate;
  final String? sipId;
  final String? goalId;
  factory Contribution.fromMap(String id, Map<String, dynamic> map) =>
      Contribution(
        id: id,
        schemeCode: map['schemeCode'] as String,
        amountPaise: map['amountPaise'] as int,
        units: (map['units'] as num).toDouble(),
        nav: (map['nav'] as num).toDouble(),
        navDate: _readDate(map['navDate']),
        effectiveDate: _readDate(map['effectiveDate']),
        sipId: map['sipId'] as String?,
        goalId: map['goalId'] as String?,
      );
  Map<String, dynamic> toMap() => {
    'schemeCode': schemeCode,
    'amountPaise': amountPaise,
    'units': units,
    'nav': nav,
    'navDate': _storeDate(navDate),
    'effectiveDate': _storeDate(effectiveDate),
    'sipId': sipId,
    'goalId': goalId,
  };
}
