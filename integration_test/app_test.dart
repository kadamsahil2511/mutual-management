import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mutual_management/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android guest can explore funds and learning and validate a plan',
    (tester) async {
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('A calmer way\nto plan ahead.'), findsOneWidget);
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Funds').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(TextField), findsWidgets);
      await tester.enterText(find.byType(TextField).first, 'Corporate');
      await tester.pumpAndSettle();
      expect(find.text('HDFC Corporate Bond Fund'), findsOneWidget);
      expect(find.text('SBI Corporate Bond Fund'), findsOneWidget);
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Learn').first);
      await tester.pumpAndSettle();
      expect(find.text('How a mutual fund works'), findsOneWidget);
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plans').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save goal'));
      await tester.tap(find.text('Save goal'));
      await tester.pumpAndSettle();
      expect(find.text('Name your goal.'), findsOneWidget);
      expect(
        find.text('Enter a positive amount, with at most 2 decimals.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
