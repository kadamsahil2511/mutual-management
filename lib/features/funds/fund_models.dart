import 'dart:math' as math;

/// A published NAV in rupees per unit. Dates represent the valuation day.
class NavPoint {
  const NavPoint({required this.date, required this.nav});

  final DateTime date;
  final double nav;
}

/// Percentage of scheme assets; [id] is the security ISIN when published.
class SecurityWeight {
  const SecurityWeight({
    required this.id,
    required this.name,
    required this.sector,
    required this.weight,
  });

  final String id;
  final String name;
  final String sector;
  final double weight;
}

/// Dated AMC information, kept separate from live NAV data.
class FundReference {
  const FundReference({
    required this.schemeCode,
    required this.name,
    required this.amc,
    required this.category,
    this.expenseRatioPct,
    this.expenseBasis,
    this.aumCrore,
    this.minSipPaise,
    this.minLumpSumPaise,
    this.minimumSourceUrl,
    this.minimumAsOfDate,
    this.manager,
    this.managerExperience,
    this.managerOtherFunds = const [],
    required this.asOfDate,
    required this.sourceUrl,
    this.benchmarkName,
    this.datedFundReturns = const {},
    this.datedBenchmarkReturns = const {},
    this.holdings = const [],
    this.holdingsDate,
    this.holdingsComplete = false,
  });

  final String schemeCode;
  final String name;
  final String amc;
  final String category;
  final double? expenseRatioPct;

  /// Source-specific definition for the disclosed expense ratio.
  final String? expenseBasis;
  final double? aumCrore;
  final int? minSipPaise;
  final int? minLumpSumPaise;
  final String? minimumSourceUrl;
  final DateTime? minimumAsOfDate;
  final String? manager;
  final String? managerExperience;
  final List<String> managerOtherFunds;
  final DateTime asOfDate;
  final String sourceUrl;
  final String? benchmarkName;

  /// Point-to-point returns (%) keyed by years: 1-year absolute, longer annualized.
  final Map<int, double> datedFundReturns;
  final Map<int, double> datedBenchmarkReturns;
  final List<SecurityWeight> holdings;
  final DateTime? holdingsDate;
  final bool holdingsComplete;

  /// Percentage of assets represented by the disclosed securities in this app.
  double get holdingsCoverage => holdings
      .fold<double>(0, (total, security) => total + security.weight)
      .clamp(0, 100)
      .toDouble();
}

class FundData {
  FundData({
    required this.reference,
    required List<NavPoint> history,
    required this.isCached,
    required this.fetchedAt,
    this.warning,
  }) : history = List<NavPoint>.unmodifiable(
         List<NavPoint>.of(history)..sort((a, b) => b.date.compareTo(a.date)),
       );

  final FundReference reference;
  final List<NavPoint> history;
  final bool isCached;
  final DateTime fetchedAt;
  final String? warning;

  NavPoint get latest {
    if (history.isEmpty) throw StateError('NAV history is unavailable.');
    return history.first;
  }

  /// The most recent observation on or before a calendar date.
  /// A date before inception/history coverage returns null.
  NavPoint? navOnOrBefore(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    for (final point in history) {
      if (!point.date.isAfter(day)) return point;
    }
    return null;
  }

  /// NAV-derived absolute one-year return or annualized longer return.
  /// No short history is extrapolated.
  /// A seven-day anchor tolerance allows weekends and exchange holidays.
  double? returnYears(int years) {
    if (years <= 0) {
      throw ArgumentError.value(years, 'years', 'Must be positive');
    }
    if (history.isEmpty) return null;
    final end = latest;
    final targetYear = end.date.year - years;
    final lastDay = DateTime(targetYear, end.date.month + 1, 0).day;
    final target = DateTime(
      targetYear,
      end.date.month,
      math.min(end.date.day, lastDay),
    );
    final start = navOnOrBefore(target);
    if (start == null ||
        start.nav <= 0 ||
        end.nav <= 0 ||
        target.difference(start.date).inDays > 7) {
      return null;
    }
    final elapsedYears = end.date.difference(start.date).inDays / 365.25;
    if (elapsedYears <= 0) return null;
    if (years == 1) return (end.nav / start.nav - 1) * 100;
    return (math.pow(end.nav / start.nav, 1 / elapsedYears) - 1) * 100;
  }
}
