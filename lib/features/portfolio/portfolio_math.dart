import '../plans/user_models.dart';

class PortfolioHolding {
  PortfolioHolding(this.schemeCode, this.investedPaise, this.units, this.value);
  final String schemeCode;
  final int investedPaise;
  final double units;
  final double? value;
  double? get gain => value == null ? null : value! - investedPaise / 100;
}

List<PortfolioHolding> deriveHoldings(
  List<Contribution> contributions,
  Map<String, double> navs,
) {
  final grouped = <String, List<Contribution>>{};
  for (final contribution in contributions) {
    grouped.putIfAbsent(contribution.schemeCode, () => []).add(contribution);
  }
  return grouped.entries.map((entry) {
    final invested = entry.value.fold<int>(0, (sum, c) => sum + c.amountPaise);
    final units = entry.value.fold<double>(0, (sum, c) => sum + c.units);
    final nav = navs[entry.key];
    return PortfolioHolding(
      entry.key,
      invested,
      units,
      nav == null ? null : units * nav,
    );
  }).toList();
}
