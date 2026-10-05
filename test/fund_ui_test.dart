import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mutual_management/core/calculations.dart';
import 'package:mutual_management/core/providers.dart';
import 'package:mutual_management/core/theme.dart';
import 'package:mutual_management/core/widgets.dart';
import 'package:mutual_management/features/funds/comparison_screen.dart';
import 'package:mutual_management/features/funds/fund_detail_screen.dart';
import 'package:mutual_management/features/funds/fund_models.dart';
import 'package:mutual_management/features/funds/fund_repository.dart';
import 'package:mutual_management/features/funds/funds_screen.dart';
import 'package:mutual_management/features/funds/reference_data.dart';
import 'package:mutual_management/features/funds/risk_screen.dart';
import 'package:mutual_management/features/overview/overview_screen.dart';
import 'package:mutual_management/features/plans/user_models.dart';

void main() {
  testWidgets('risk results require all five answers and can restart', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: const Scaffold(body: RiskScreen()),
      ),
    );
    expect(find.text('Your learning profile'), findsNothing);
    for (var question = 0; question < 5; question++) {
      await tester.ensureVisible(
        find.byKey(ValueKey('risk-option-$question-0')),
      );
      await tester.tap(find.byKey(ValueKey('risk-option-$question-0')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('risk-next')));
      await tester.tap(find.byKey(const ValueKey('risk-next')));
      await tester.pumpAndSettle();
    }
    expect(find.text('Your learning profile'), findsOneWidget);
    expect(find.text('Capital preservation'), findsOneWidget);
    await tester.ensureVisible(find.text('Start again'));
    await tester.tap(find.text('Start again'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('risk-option-0-0')), findsOneWidget);
    expect(find.text('Your learning profile'), findsNothing);
  });

  testWidgets('page content and risk answers fit at 320px with double text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const Scaffold(body: RiskScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('money uses Indian grouping and finite values only', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(children: [MoneyText(123456.78), MoneyText(double.nan)]),
        ),
      ),
    );
    expect(find.text('₹1,23,456.78'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('fund search and category filter narrow the catalogue', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fundProvider.overrideWith((ref, code) async => _fund(code)),
        ],
        child: MaterialApp(
          theme: buildTheme(),
          home: const Scaffold(body: FundsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('HDFC Flexi Cap Fund'), findsOneWidget);
    expect(find.text('SBI Flexicap Fund'), findsOneWidget);
    for (final code in ['118955', '119718', '118987']) {
      await tester.ensureVisible(find.byKey(ValueKey('compare-$code')));
      await tester.tap(find.byKey(ValueKey('compare-$code')));
      await tester.pumpAndSettle();
    }
    expect(find.text('3 of 3 funds selected'), findsOneWidget);
    final fourth = tester.widget<TextButton>(
      find.byKey(const ValueKey('compare-146215')),
    );
    expect(fourth.onPressed, isNull);
    await tester.ensureVisible(find.text('Clear selection'));
    await tester.tap(find.text('Clear selection'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Corporate Bond').first);
    await tester.tap(find.text('Corporate Bond').first);
    await tester.pumpAndSettle();
    expect(find.text('HDFC Corporate Bond Fund'), findsOneWidget);
    expect(find.text('HDFC Flexi Cap Fund'), findsNothing);
    await tester.enterText(find.byKey(const ValueKey('fund-search')), '146215');
    await tester.pumpAndSettle();
    expect(find.text('SBI Corporate Bond Fund'), findsOneWidget);
    expect(find.text('HDFC Corporate Bond Fund'), findsNothing);
  });

  testWidgets('NAV retry bypasses the six-hour cache', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = _TrackingFundRepository(preferences);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fundRepositoryProvider.overrideWithValue(repository),
          fundProvider.overrideWith(
            (ref, code) async => throw StateError('offline'),
          ),
        ],
        child: MaterialApp(
          theme: buildTheme(),
          home: const Scaffold(body: FundsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Retry NAV').first);
    await tester.tap(find.text('Retry NAV').first);
    await tester.pumpAndSettle();
    expect(repository.lastForceRefresh, isTrue);
  });

  testWidgets(
    'overview has no horizontal overflow at supported widths and 200% text',
    (tester) async {
      final widths = [320.0, 390.0, 640.0, 768.0, 1024.0, 1280.0, 1920.0];
      for (final width in widths) {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              goalsProvider.overrideWith((ref) => Stream.value(<Goal>[])),
              sipsProvider.overrideWith((ref) => Stream.value(<Sip>[])),
              contributionsProvider.overrideWith(
                (ref) => Stream.value(<Contribution>[]),
              ),
            ],
            child: MaterialApp(
              theme: buildTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: const Scaffold(body: OverviewScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Overview overflow at $width px and 200% text',
        );
      }
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    },
  );

  testWidgets('fund detail separates latest NAV from dated benchmark returns', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fundProvider.overrideWith((ref, code) async => _fund(code)),
        ],
        child: MaterialApp(
          theme: buildTheme(),
          home: const Scaffold(body: FundDetailScreen(schemeCode: '118955')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Valuation date'), findsOneWidget);
    expect(find.textContaining('Unavailable'), findsWidgets);
    expect(find.textContaining('Dated'), findsWidgets);
    expect(find.textContaining('1-year absolute return'), findsOneWidget);
    expect(find.textContaining('Minimum monthly SIP'), findsOneWidget);
    expect(
      find.textContaining('Minimum investment source · 5 Oct 2026'),
      findsOneWidget,
    );
    final publishedOneYear = fundCatalog.first.datedFundReturns[1]!;
    expect(find.textContaining(percentLabel(publishedOneYear)), findsOneWidget);
  });

  testWidgets('comparison shows dated returns and discloses missing holdings', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fundProvider.overrideWith((ref, code) async => _fund(code)),
        ],
        child: MaterialApp(
          theme: buildTheme(),
          home: const Scaffold(
            body: ComparisonScreen(schemeCodes: ['118955', '119718']),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('HDFC Flexi Cap Fund'), findsWidgets);
    expect(find.text('SBI Flexicap Fund'), findsWidgets);
    expect(find.textContaining('Latest published NAV'), findsNWidgets(2));
    expect(find.textContaining('Reference date'), findsNWidgets(2));
    expect(find.textContaining('1-year absolute return'), findsNWidgets(2));
    final overlap = overlapPercent(
      fundCatalog[0].holdings,
      fundCatalog[1].holdings,
    );
    expect(
      find.text('${overlap.toStringAsFixed(2)}% reported overlap'),
      findsOneWidget,
    );
    expect(find.textContaining('Partial disclosure'), findsWidgets);
  });
}

FundData _fund(String code) {
  final reference = fundCatalog.firstWhere((fund) => fund.schemeCode == code);
  return FundData(
    reference: reference,
    history: [NavPoint(date: DateTime(2026, 10, 2), nav: 100)],
    isCached: false,
    fetchedAt: DateTime(2026, 10, 5),
  );
}

class _TrackingFundRepository extends FundRepository {
  _TrackingFundRepository(super.preferences);
  bool? lastForceRefresh;
  @override
  Future<FundData> fetchFund(
    String schemeCode, {
    bool forceRefresh = false,
  }) async {
    lastForceRefresh = forceRefresh;
    return _fund(schemeCode);
  }
}
