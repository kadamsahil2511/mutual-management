import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mutual_management/app.dart';
import 'package:mutual_management/core/providers.dart';
import 'package:mutual_management/features/funds/fund_models.dart';
import 'package:mutual_management/features/funds/reference_data.dart';
import 'package:mutual_management/features/plans/user_models.dart';

Future<GoRouter> openApp(
  WidgetTester tester, {
  String path = '/',
  bool missingNav = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = createRouter(initialLocation: path);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(null)),
        goalsProvider.overrideWith((ref) => Stream.value(<Goal>[])),
        sipsProvider.overrideWith((ref) => Stream.value(<Sip>[])),
        contributionsProvider.overrideWith(
          (ref) => Stream.value(
            missingNav
                ? [
                    Contribution(
                      id: 'x',
                      schemeCode: '118955',
                      amountPaise: 100000,
                      units: 10,
                      nav: 100,
                      navDate: DateTime(2026, 10, 1),
                      effectiveDate: DateTime(2026, 10, 1),
                    ),
                  ]
                : <Contribution>[],
          ),
        ),
        fundProvider.overrideWith((ref, code) async {
          if (missingNav) throw StateError('NAV unavailable');
          return FundData(
            reference: fundCatalog.firstWhere((f) => f.schemeCode == code),
            history: [NavPoint(date: DateTime(2026, 10, 1), nav: 100)],
            isCached: false,
            fetchedAt: DateTime(2026, 10, 5),
          );
        }),
      ],
      child: MutualManagementApp(router: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

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
    'phone navigation opens a separate goal form and Back returns to Plans',
    (tester) async {
      final router = await openApp(tester);
      expect(find.byType(NavigationDestination), findsNWidgets(5));
      expect(find.text('A calmer way\nto plan ahead.'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('nav-/plans')));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);
      await tester.ensureVisible(find.text('Create goal'));
      await tester.tap(find.text('Create goal'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/plans/goal/new');
      expect(find.byType(NavigationBar), findsNothing);
      await tester.ensureVisible(find.text('Save goal'));
      await tester.tap(find.text('Save goal'));
      await tester.pumpAndSettle();
      expect(find.text('Name your goal.'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/plans');
      expect(find.byType(NavigationBar), findsOneWidget);
    },
  );

  testWidgets(
    'More exposes calculators and reset has its own validation screen',
    (tester) async {
      final router = await openApp(tester, path: '/more');
      await tester.tap(find.text('Calculators'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/calculators');
      expect(find.text('Monthly amount (₹)'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Risk comfort'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/risk');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      router.push('/auth/reset');
      await tester.pumpAndSettle();
      expect(find.text('Send reset link'), findsOneWidget);
      expect(find.text('Password'), findsNothing);
      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();
      expect(find.textContaining('valid email'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'mobile dashboard does not show zero for a portfolio with missing NAV',
    (tester) async {
      await openApp(tester, missingNav: true);
      expect(find.text('Unavailable'), findsOneWidget);
      expect(find.text('₹0.00'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
