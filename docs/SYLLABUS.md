# Syllabus and case-study mapping

Sources read locally: case study 132 in **Cross Platform.pdf**, and **SEM5 - Cross Platform App Development.xlsx**, Assignment `F16:I16`. This mapping describes the software; it does not claim completion of separate classroom activities.

| Requirement | Implementation/evidence |
|---|---|
| Four or more screens | Five mobile tabs, six desktop destinations and dedicated detail, goal/SIP/contribution, activity/receipt, account/recovery, comparison, risk and article routes in `lib/app.dart` |
| Riverpod or BLoC | Manually declared providers in `lib/core/providers.dart` |
| API or Firestore | MFAPI historical NAV, Firebase Auth and owner-scoped Firestore records |
| Form validation | Email/password, exact paise parsing, dates, SIP amounts, assumptions and calculator inputs |
| Local storage | SharedPreferences public NAV cache; successful responses expire after six hours |
| Material 3 and responsive UI | Central theme, local fonts, phone bottom navigation, adaptive desktop/drawer navigation, narrow layouts and 200% text checks |
| Feature folders and repository layer | `lib/features/` with three concrete repositories |
| Analyze/tests on each push | GitHub Actions formatting, analysis, unit/widget tests, web build and Firestore emulator tests |
| Public source, APK, live demo | GitHub, signed release APK and Vercel links in README |
| Fund discovery/risk questionnaire | Search, three category filters and five educational risk questions |
| Goals/flexible SIP | Editable goals; monthly/quarterly plans, due selection, explicit recording and cancellation |
| Portfolio X-ray | Value-weighted sectors, matching-ISIN overlap and visible partial coverage |
| Returns/benchmark/expenses/managers/AUM/minimums | Current NAV-derived returns and separately dated AMC disclosures; unavailable values labelled |
| Articles/videos/calculators | Six original articles, official videos, SIP/lump-sum/goal calculators |
| Bank deposits | Dated published rates, bank links and estimated maturity |
| Pricing examples | Brief figures labelled as case-study examples in Learn; stock trading informational |

The syllabus also calls for genuine development over weeks, handwritten work, classroom participation, peer assessment and a live surprise-feature exercise. Commits reflect actual implementation work; none of those separate activities or a weeks-long history is fabricated here.
