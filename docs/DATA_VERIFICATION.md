# Data verification record

Verified against the downloaded AMC August 2026 factsheets and the official NSE equity master on 5 October 2026. The mutual-fund catalog is in `lib/features/funds/reference_data.dart`; there is no `assets/data/funds.json` catalog file. The exact six direct-growth codes are 118955, 119718, 118987, 146215, 119062, and 119609.

| Scheme | AUM (₹ crore) | Direct BER | 1 / 3 / 5 year fund return (%) | 1 / 3 / 5 year benchmark (%) |
| --- | ---: | ---: | --- | --- |
| HDFC Flexi Cap | 113,606.47 | 0.67% | 6.84 / 17.63 / 18.46 | 5.31 / 12.54 / 11.12 |
| SBI Flexicap | 23,228.68 | 0.72% | 4.34 / 10.05 / 9.10 | 4.69 / 12.08 / 10.90 |
| HDFC Corporate Bond | 30,286.08 | 0.38% | 5.14 / 7.15 / 6.30 | 4.27 / 6.46 / 5.63 |
| SBI Corporate Bond | 22,120.98 | 0.31% | 5.45 / 7.30 / 6.29 | 4.27 / 6.46 / 5.63 |
| HDFC Aggressive Hybrid | 22,296.62 | 1.06% | -0.72 / 7.68 / 9.06 | 0.89 / 8.09 / 7.46 |
| SBI Aggressive Hybrid | 88,692.67 | 0.55% | 8.44 / 13.50 / 10.62 | 4.32 / 10.13 / 8.95 |

All reference figures and holdings are dated 31 August 2026 except HDFC minimum-investment details, which carry their separately recorded 5 October 2026 official product-page date. SBI minimums and manager experience are from the scheme panels. The SBI Corporate Bond and SBI Aggressive Hybrid panels both name Rajeev Radhakrishnan; their `managerOtherFunds` entries cross-reference those disclosed assignments. Anup Upadhyay's SBI Flexicap factsheet says he manages two schemes but does not identify the second by name, so the list remains empty.

The HDFC and SBI expense values are both BER but have different stated inclusions. Category averages and cross-AMC comparisons are therefore unavailable; the UI checks the stored expense basis before computing an average. SBI's separate disclosed Direct TER figures are 1.27%, 0.37%, and 0.73% for Flexicap, Corporate Bond, and Aggressive Hybrid respectively. A like-for-like HDFC TER was not verified in these sources.

The holdings list contains partial top equity positions from HDFC Flexi Cap, SBI Flexicap, HDFC Aggressive Hybrid, and SBI Aggressive Hybrid. ISINs were checked by issuer name against the official NSE equity master; the test checks that repeated ISINs keep a consistent normalized company name. For example, INE917I01010 is Bajaj Auto and INE296A01032 is Bajaj Finance. Holdings are marked incomplete. Debt issuer aggregates are not assigned ISINs or used for overlap, and the corporate-bond schemes have no holdings listed here.

NAV repository validation checks successful response status, scheme-code identity, dates, and positive finite NAVs; cache age is six hours and stale cache is labeled on offline fallback. `returnYears(1)` computes absolute percent change after requiring a valid positive anchor within seven days of the one-year target. Longer horizons annualize over the observed elapsed interval after the same anchor check. A leap-year regression distinguishes the absolute one-year value from annualizing by 365.25 days. Category average detection requires matching non-null expense basis strings; the current paired categories have different bases, so no average is supported.

Verification run: JSON parsing for `assets/data/deposits.json` and `assets/data/learning.json`, `flutter analyze lib/features/funds/fund_models.dart lib/features/funds/reference_data.dart test/fund_data_test.dart`, and `flutter test test/fund_data_test.dart test/calculations_test.dart` all pass (18 tests). The principal remaining data limit is coverage: only four of six schemes have partial equity holdings, while no individual debt security holdings are cataloged; all disclosed lists remain explicitly partial.
