# Mutual Management implementation contracts

Historical contracts used during the version 1.0 build. Ownership assignments and original route/layout notes below describe that implementation stage. Version 1.1 adds dedicated mobile routes and bottom navigation; use [the current project handbook](../README.md), [mobile UX audit](MOBILE_UX_AUDIT.md) and current source code for the delivered behavior.

All amounts are integer paise, dates are DateTime, scheme codes are strings. Plain classes with named constructors, no code generation. Flutter/Riverpod providers live in lib/core/providers.dart, theme in lib/core/theme.dart, router in lib/app.dart. Do not edit another worker's files. Root handles commits.

## Worker A owns
lib/features/auth/auth_repository.dart: AuthRepository(FirebaseAuth auth), Stream<User?> authStateChanges(), User? get currentUser, Future<void> signIn(email,password), register(email,password,name), resetPassword(email), signOut(). Use positional arguments.
lib/features/plans/user_models.dart:
Goal({required String id, required String name, required int targetPaise, required DateTime targetDate, double assumedAnnualReturn=0});
Sip({required String id, required String schemeCode, required int amountPaise, required DateTime startDate, int intervalMonths=1, String? goalId, bool isActive=true});
Contribution({required String id, required String schemeCode, required int amountPaise, required double units, required double nav, required DateTime navDate, required DateTime effectiveDate, String? sipId, String? goalId});
Every field final, constructors expose these names. fromMap/toMap for Firestore. Optional nullable associations serialize consistently.
lib/features/plans/user_repository.dart: UserRepository(FirebaseFirestore firestore, String uid); watchGoals(), watchSips(), watchContributions() streams of lists; saveGoal(Goal), saveSip(Sip), cancelSip(String id), recordContribution(Contribution) -> Future<bool> (false = duplicate), saveProfile(String name). All owner-only records under mutualManagementUsers/{uid}. Deterministic contribution IDs for SIPs: '${sip.id}_${yyyy-MM-dd}' enforced as far as practical in rules.
Also firebase_options.dart, Firebase project/app configuration, rules+emulator tests. Root owns main.dart & providers; report Firebase initialization details. Never delete resources or change billing. Auth persistence browser local okay, Firestore persistent private caching disabled.

## Worker B owns
lib/features/funds/fund_models.dart:
NavPoint({required DateTime date, required double nav});
SecurityWeight({required String id, required String name, required String sector, required double weight}); (weight percent 0..100)
FundReference({required String schemeCode, required String name, required String amc, required String category, double? expenseRatioPct, double? aumCrore, int? minSipPaise, int? minLumpSumPaise, String? manager, String? managerExperience, List<String> managerOtherFunds=const [], required DateTime asOfDate, required String sourceUrl, String? benchmarkName, Map<int,double> datedFundReturns=const {}, Map<int,double> datedBenchmarkReturns=const {}, List<SecurityWeight> holdings=const [], DateTime? holdingsDate, bool holdingsComplete=false});
FundData({required FundReference reference, required List<NavPoint> history, required bool isCached, required DateTime fetchedAt, String? warning}); getters latest (NavPoint), returnYears(int years) -> double? percent, navOnOrBefore(DateTime) -> NavPoint?.
lib/features/funds/reference_data.dart: final List<FundReference> fundCatalog containing exact six schemes 118955,119718,118987,146215,119062,119609.
lib/features/funds/fund_repository.dart: FundRepository(SharedPreferences preferences,{http.Client? client}); fetchFund(String schemeCode,{bool forceRefresh=false}) -> Future<FundData>. six hour cache, explicit errors, timeout/retry/cache labels.
lib/core/calculations.dart: double futureValue({required double initial, required double monthly, required int months, double annualReturn=0}); double requiredMonthly({required double target, required double initial, required int months, double annualReturn=0}); DateTime installmentDate(DateTime start,int index,int intervalMonths); String installmentId(String sipId,DateTime date); double overlapPercent(List<SecurityWeight> a,List<SecurityWeight> b); Map<String,double> sectorAllocation(Map<FundReference,double> values); root can derive portfolio from contributions directly.
assets/data/deposits.json: array objects bank, tenureMonths, annualRate, effectiveDate ISO, sourceUrl, note. Official, real dated published rates only. assets/data/learning.json: array objects id,title,summary,body,sourceUrl,videoUrl? six articles, official links. docs/DATA_SOURCES.md provenance. Meaningful unit tests. Preserve unavailable metadata explicitly.

## Worker C owns
lib/core/widgets.dart and lib/features/overview/overview_screen.dart, lib/features/funds/funds_screen.dart, fund_detail_screen.dart, comparison_screen.dart, risk_screen.dart and relevant UI tests.
Root owns all other UI: auth, plans, portfolio, learn/deposits.
Screen classes: OverviewScreen(), FundsScreen(), FundDetailScreen({required String schemeCode}), ComparisonScreen({required List<String> schemeCodes}), RiskScreen(). All const constructors where possible.
Routes: /, /funds, /funds/:code, /compare?codes=118955,119718, /risk, /portfolio, /plans, /learn, /learn/:id, /deposits, /auth?next=<encoded local path>.
For contribution action navigate to /portfolio?invest=<code>. Plans /plans?scheme=<code>. Root owns forms.
Shared widgets (C creates): PageFrame({required String title,String? subtitle,required List<Widget> children,Widget? action}), AppCard({required Widget child,Color? color,EdgeInsetsGeometry? padding}), MoneyText(num value,{double size=18,Color? color}) value in rupees, EmptyState({required String title,required String message,Widget? action}), SourceLink({required String label,required String url}). All root may consume. No standalone Scaffold in screens; shell handles nav and scrolling can live in PageFrame. Overview can custom scroll.
Core theme root exports: AppColors primary,primaryActive,primaryDisabled,canvas,soft,strong,dark,darkElevated,hairline,ink,body,muted,onDarkSoft,up,down,yellow constants; AppSpacing section=96 etc. Theme function buildTheme(); numberStyle({double size=18,Color? color}) TextStyle.
Providers root exports: preferencesProvider Provider<SharedPreferences>, authRepositoryProvider Provider<AuthRepository>, authStateProvider StreamProvider<User?>, userRepositoryProvider Provider<UserRepository?>, goalsProvider/sipsProvider/contributionsProvider StreamProvider<List<Model>>, fundRepositoryProvider Provider<FundRepository>, fundProvider FutureProvider.family<FundData,String> (refresh via ref.invalidate(fundProvider(code))). Auth state use .value. fundCatalog import directly.

## Design and behavior
Read DESIGN.md. Inter locally bundled for body, JetBrains Mono for numbers. Blue #0052ff, white/gray, dark layered overview hero. Weight 400 display, 24 radius cards, 12 radius inputs, pill CTA, max width 1200. Mobile 320..639 16 padding 36-40 hero, tablet two cols 24 padding 64 hero, desktop 3 cols 80 hero. All targets 48 px, scale text 200%. Top shell handles drawer under 768 (or sooner at large type). No invented finance data, current NAV vs dated benchmark distinguished. Transactions visibly simulated. Fresh account empty. Category expense 'Selected-category average · 2 funds'. Pairwise overlap and sector charts disclose holdings coverage. No automatic execution.
