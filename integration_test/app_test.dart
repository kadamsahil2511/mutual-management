import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mutual_management/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android guest can use mobile navigation and goal editor', (
    tester,
  ) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Your money, in view.'), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-/')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-/funds')));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byType(TextField), findsWidgets);
    await tester.enterText(find.byType(TextField).first, 'Corporate');
    await tester.pumpAndSettle();
    expect(find.text('HDFC Corporate Bond Fund'), findsOneWidget);
    expect(find.text('SBI Corporate Bond Fund'), findsOneWidget);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-/plans')));
    await tester.pumpAndSettle();
    expect(find.text('Goals'), findsOneWidget);
    expect(find.text('SIPs'), findsOneWidget);
    await tester.tap(find.text('Create goal'));
    await tester.pumpAndSettle();
    expect(find.text('Create a goal'), findsWidgets);
    expect(find.byKey(const ValueKey('nav-/plans')), findsNothing);
    await tester.tap(find.text('Save goal'));
    await tester.pumpAndSettle();
    expect(find.text('Name your goal.'), findsOneWidget);
    expect(
      find.text('Enter a positive amount, with at most 2 decimals.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Create goal'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nav-/more')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calculators'));
    await tester.pumpAndSettle();
    expect(find.text('Calculators'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Learn').first);
    await tester.pumpAndSettle();
    expect(find.text('How a mutual fund works'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
