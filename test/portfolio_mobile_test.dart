import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutual_management/core/providers.dart';
import 'package:mutual_management/core/theme.dart';
import 'package:mutual_management/features/funds/fund_models.dart';
import 'package:mutual_management/features/funds/reference_data.dart';
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
    'mobile portfolio keeps summary and history, moves entry to CTA',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final contribution = Contribution(
        id: 'c1',
        schemeCode: '118955',
        amountPaise: 100000,
        units: 10,
        nav: 100,
        navDate: DateTime(2026, 10, 1),
        effectiveDate: DateTime(2026, 10, 2),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            contributionsProvider.overrideWith(
              (ref) => Stream.value([contribution]),
            ),
            fundProvider.overrideWith(
              (ref, code) async => FundData(
                reference: fundCatalog.firstWhere(
                  (fund) => fund.schemeCode == code,
                ),
                history: [NavPoint(date: DateTime(2026, 10, 1), nav: 100)],
                isCached: false,
                fetchedAt: DateTime(2026, 10, 2),
              ),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: PortfolioScreen())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Add simulation'), findsOneWidget);
      expect(find.text('Recent activity'), findsOneWidget);
      expect(find.text('Record a simulated contribution'), findsNothing);
      expect(find.text('HDFC Flexi Cap Fund'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('activity gives a clear guest state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const MaterialApp(home: Scaffold(body: ActivityScreen())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sign in to view activity'), findsOneWidget);
  });

  testWidgets('populated portfolio, activity, and receipt fit at phone scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final records = [
      for (var i = 0; i < 4; i++)
        Contribution(
          id: 'record-$i',
          schemeCode: '118955',
          amountPaise: 987654321,
          units: 12345.678901,
          nav: 123.4567,
          navDate: DateTime(2026, 10, 1),
          effectiveDate: DateTime(2026, 10, 2 + i),
          sipId: i.isEven ? 'sip-$i' : null,
        ),
    ];
    Widget screen(Widget child) => ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(_StubUser())),
        contributionsProvider.overrideWith((ref) => Stream.value(records)),
        fundProvider.overrideWith(
          (ref, code) async => FundData(
            reference: fundCatalog.firstWhere(
              (fund) => fund.schemeCode == code,
            ),
            history: [NavPoint(date: DateTime(2026, 10, 1), nav: 123.4567)],
            isCached: false,
            fetchedAt: DateTime(2026, 10, 5),
          ),
        ),
      ],
      child: MaterialApp(
        theme: buildTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(body: child),
      ),
    );

    for (final child in <Widget>[
      const PortfolioScreen(),
      const ActivityScreen(),
      const ContributionDetailScreen(contributionId: 'record-0'),
    ]) {
      await tester.pumpWidget(screen(child));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}

class _StubUser extends Fake implements User {}
