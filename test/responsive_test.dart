import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutual_management/app.dart';
import 'package:mutual_management/core/providers.dart';
import 'package:mutual_management/core/theme.dart';
import 'package:mutual_management/features/auth/auth_screen.dart';
import 'package:mutual_management/features/more/more_screen.dart';
import 'package:mutual_management/features/deposits/deposits_screen.dart';
import 'package:mutual_management/features/funds/comparison_screen.dart';
import 'package:mutual_management/features/funds/fund_detail_screen.dart';
import 'package:mutual_management/features/funds/fund_models.dart';
import 'package:mutual_management/features/funds/funds_screen.dart';
import 'package:mutual_management/features/funds/reference_data.dart';
import 'package:mutual_management/features/funds/risk_screen.dart';
import 'package:mutual_management/features/learn/learn_screen.dart';
import 'package:mutual_management/features/overview/overview_screen.dart';
import 'package:mutual_management/features/plans/plans_screen.dart';
import 'package:mutual_management/features/portfolio/portfolio_screen.dart';
import 'package:mutual_management/features/plans/user_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final inter = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await inter.load();
    final mono = FontLoader('JetBrains Mono')
      ..addFont(rootBundle.load('assets/fonts/JetBrainsMono.ttf'));
    await mono.load();
  });
  testWidgets(
    'phone bottom navigation and wider navigation fit at enlarged text',
    (tester) async {
      final router = createRouter(initialLocation: '/');
      addTearDown(router.dispose);
      final shellFailures = <String>[];
      for (final width in [
        320.0,
        640.0,
        1024.0,
        1050.0,
        1100.0,
        1280.0,
        1920.0,
      ]) {
        for (final scale in [1.0, 2.0]) {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                authStateProvider.overrideWith((ref) => Stream.value(null)),
                goalsProvider.overrideWith((ref) => Stream.value(<Goal>[])),
                sipsProvider.overrideWith((ref) => Stream.value(<Sip>[])),
                contributionsProvider.overrideWith(
                  (ref) => Stream.value(<Contribution>[]),
                ),
                fundProvider.overrideWith((ref, code) async => _fund(code)),
              ],
              child: MaterialApp.router(
                theme: buildTheme(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                routerConfig: router,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final initialError = tester.takeException();
          if (initialError != null) {
            shellFailures.add(
              'shell at $width px / $scale scale: $initialError',
            );
            continue;
          }
          if (width < 768) {
            expect(find.byType(NavigationBar), findsOneWidget);
            expect(find.byTooltip('Open navigation menu'), findsNothing);
            for (final destination in [
              '/',
              '/funds',
              '/portfolio',
              '/plans',
              '/more',
            ]) {
              final size = tester.getSize(
                find.byKey(ValueKey('nav-$destination')),
              );
              expect(size.width, greaterThanOrEqualTo(48));
              expect(size.height, greaterThanOrEqualTo(48));
            }
            continue;
          }
          final compact = width < 1050 || scale > 17 / 14;
          final menu = find.byTooltip('Open navigation menu');
          expect(
            menu,
            compact ? findsOneWidget : findsNothing,
            reason: 'navigation at $width px / $scale scale',
          );
          if (compact) {
            final size = tester.getSize(menu);
            expect(size.width, greaterThanOrEqualTo(48));
            expect(size.height, greaterThanOrEqualTo(48));
            final scaffold = tester.widget<Scaffold>(
              find.byType(Scaffold).first,
            );
            expect(
              scaffold.drawer,
              isNotNull,
              reason: 'compact drawer at $width px / $scale scale',
            );
          } else {
            final fundsButton = find
                .ancestor(
                  of: find.text('Funds').first,
                  matching: find.byType(TextButton),
                )
                .first;
            final size = tester.getSize(fundsButton);
            expect(size.width, greaterThanOrEqualTo(48));
            expect(size.height, greaterThanOrEqualTo(48));
          }
        }
      }
      expect(shellFailures, isEmpty, reason: shellFailures.join('\n'));
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    },
  );
  testWidgets('populated plans and portfolio cards fit on a narrow screen', (
    tester,
  ) async {
    final goal = Goal(
      id: 'home',
      name: 'A first home',
      targetPaise: 250000000,
      targetDate: DateTime(2032, 12, 31),
      assumedAnnualReturn: 6,
    );
    final sip = Sip(
      id: 'sip1',
      schemeCode: '118955',
      amountPaise: 500000,
      startDate: DateTime(2026, 9, 30),
      goalId: goal.id,
    );
    final contribution = Contribution(
      id: 'one',
      schemeCode: '118955',
      amountPaise: 500000,
      units: 50,
      nav: 100,
      navDate: DateTime(2026, 9, 29),
      effectiveDate: DateTime(2026, 9, 30),
      sipId: sip.id,
      goalId: goal.id,
    );
    for (final screen in <Widget Function()>[
      () => const PlansScreen(),
      () => const PortfolioScreen(),
    ]) {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            goalsProvider.overrideWith((ref) => Stream.value([goal])),
            sipsProvider.overrideWith((ref) => Stream.value([sip])),
            contributionsProvider.overrideWith(
              (ref) => Stream.value([contribution]),
            ),
            fundProvider.overrideWith((ref, code) async => _fund(code)),
          ],
          child: MaterialApp(
            theme: buildTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(body: screen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('all screens fit supported widths at 200% text scale', (
    tester,
  ) async {
    const widths = [
      320.0,
      390.0,
      640.0,
      768.0,
      1024.0,
      1050.0,
      1100.0,
      1280.0,
      1920.0,
    ];
    final screens = <(String, Widget Function())>[
      ('overview', () => const OverviewScreen()),
      ('fund catalogue', () => const FundsScreen()),
      ('fund detail', () => const FundDetailScreen(schemeCode: '118955')),
      (
        'comparison',
        () => const ComparisonScreen(schemeCodes: ['118955', '119718']),
      ),
      ('risk', () => const RiskScreen()),
      ('plans', () => const PlansScreen()),
      ('portfolio', () => const PortfolioScreen()),
      ('learning', () => const LearnScreen()),
      ('deposits', () => const DepositsScreen()),
      ('authentication', () => const AuthScreen()),
      ('goal editor', () => const GoalEditorScreen()),
      ('SIP editor', () => const SipEditorScreen()),
      ('contribution editor', () => const ContributionEditorScreen()),
      ('activity', () => const ActivityScreen()),
      ('More hub', () => const MoreScreen()),
      ('account', () => const AccountScreen()),
      ('password reset', () => const PasswordResetScreen()),
      ('calculators', () => const CalculatorsScreen()),
    ];

    final failures = <String>[];
    for (final width in widths) {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      for (final (name, screen) in screens) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith((ref) => Stream.value(null)),
              goalsProvider.overrideWith((ref) => Stream.value(<Goal>[])),
              sipsProvider.overrideWith((ref) => Stream.value(<Sip>[])),
              contributionsProvider.overrideWith(
                (ref) => Stream.value(<Contribution>[]),
              ),
              fundProvider.overrideWith((ref, code) async => _fund(code)),
            ],
            child: MaterialApp(
              theme: buildTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: Scaffold(body: screen()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final error = tester.takeException();
        if (error != null) failures.add('$name at $width px: $error');
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}

FundData _fund(String code) => FundData(
  reference: fundCatalog.firstWhere((fund) => fund.schemeCode == code),
  history: [NavPoint(date: DateTime(2026, 10, 2), nav: 100)],
  isCached: false,
  fetchedAt: DateTime(2026, 10, 5),
);
