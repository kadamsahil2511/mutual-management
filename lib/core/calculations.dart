import 'dart:math' as math;

import '../features/funds/fund_models.dart';

/// Rupee projection with contributions at the end of each month.
/// [annualReturn] is an effective annual percentage, not a promised return.
double futureValue({
  required double initial,
  required double monthly,
  required int months,
  double annualReturn = 0,
}) {
  _validateProjection(initial, monthly, months, annualReturn);
  if (months == 0) return initial;
  final rate = math.pow(1 + annualReturn / 100, 1 / 12) - 1;
  if (rate.abs() < 1e-12) return initial + monthly * months;
  final growth = math.pow(1 + rate, months);
  return initial * growth + monthly * (growth - 1) / rate;
}

/// Required end-of-month contribution in rupees; never less than zero.
double requiredMonthly({
  required double target,
  required double initial,
  required int months,
  double annualReturn = 0,
}) {
  _validateProjection(initial, target, months, annualReturn);
  if (months == 0) return initial >= target ? 0 : double.infinity;
  final rate = math.pow(1 + annualReturn / 100, 1 / 12) - 1;
  if (rate.abs() < 1e-12) return math.max(0, (target - initial) / months);
  final growth = math.pow(1 + rate, months);
  return math.max(0, (target - initial * growth) * rate / (growth - 1));
}

void _validateProjection(
  double initial,
  double payment,
  int months,
  double rate,
) {
  if (!initial.isFinite || initial < 0 || !payment.isFinite || payment < 0) {
    throw ArgumentError('Amounts must be finite and non-negative.');
  }
  if (months < 0 || !rate.isFinite || rate <= -100) {
    throw ArgumentError('Months must be non-negative and return above -100%.');
  }
}

/// Index zero is the start date. Each later date is calculated from the
/// original day, so a 31 January schedule recovers 31 March after February.
DateTime installmentDate(DateTime start, int index, int intervalMonths) {
  if (index < 0 || intervalMonths <= 0) {
    throw ArgumentError('Index must be non-negative and interval positive.');
  }
  final month = DateTime(start.year, start.month + index * intervalMonths);
  final day = math.min(start.day, DateTime(month.year, month.month + 1, 0).day);
  return DateTime(month.year, month.month, day);
}

String installmentId(String sipId, DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${sipId}_$year-$month-$day';
}

/// Sum of the smaller asset weight for each matching security identifier.
/// Partial portfolios produce a disclosed overlap, not a normalized estimate.
double overlapPercent(List<SecurityWeight> a, List<SecurityWeight> b) {
  Map<String, double> byId(List<SecurityWeight> holdings) {
    final result = <String, double>{};
    for (final holding in holdings) {
      if (holding.id.trim().isEmpty ||
          !holding.weight.isFinite ||
          holding.weight <= 0) {
        continue;
      }
      final id = holding.id.trim().toUpperCase();
      result[id] = (result[id] ?? 0) + holding.weight;
    }
    return result;
  }

  final first = byId(a);
  final second = byId(b);
  var overlap = 0.0;
  for (final entry in first.entries) {
    overlap += math.min(entry.value, second[entry.key] ?? 0);
  }
  return overlap.clamp(0, 100).toDouble();
}

/// Value-weighted sector percentages. Unreported assets remain visible, so
/// partial holdings never appear to describe the whole portfolio.
Map<String, double> sectorAllocation(Map<FundReference, double> values) {
  final included = values.entries
      .where((entry) => entry.value.isFinite && entry.value > 0)
      .toList();
  final total = included.fold<double>(0, (sum, entry) => sum + entry.value);
  if (total == 0) return {};
  final result = <String, double>{};
  for (final entry in included) {
    final fraction = entry.value / total;
    var covered = 0.0;
    for (final holding in entry.key.holdings) {
      if (!holding.weight.isFinite || holding.weight <= 0) continue;
      final weight = math.min(holding.weight, 100 - covered);
      if (weight <= 0) break;
      final sector = holding.sector.trim().isEmpty
          ? 'Sector unavailable'
          : holding.sector;
      result[sector] = (result[sector] ?? 0) + weight * fraction;
      covered += weight;
    }
    final missing = (100 - covered) * fraction;
    if (missing > 0) {
      result['Unavailable / unreported'] =
          (result['Unavailable / unreported'] ?? 0) + missing;
    }
  }
  return result;
}
