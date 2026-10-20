import 'package:bank_app/screens/lock_screen.dart';
import 'package:bank_app/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakshak_core/rakshak_core.dart';

void main() {
  test('five distinct banks', () {
    expect(BankBrand.all.length, 5);
    expect(BankBrand.all.map((b) => b.code).toSet().length, 5);
  });

  testWidgets('lock screen asks for MPIN and blocks back button', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LockScreen(onLaunch: true)));
    expect(find.text('Enter your 4-digit MPIN'), findsOneWidget);
    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);
  });

  testWidgets('new PIN must be different and not easy to guess', (tester) async {
    String? saved;
    await tester.pumpWidget(MaterialApp(
      home: ChangeSecretScreen(title: 'Change MPIN', what: 'MPIN', submit: (c, n) async => saved = n),
    ));
    final fields = find.byType(TextFormField);
    Future<void> attempt(String current, String next) async {
      await tester.enterText(fields.at(0), current);
      await tester.enterText(fields.at(1), next);
      await tester.enterText(fields.at(2), next);
      await tester.tap(find.widgetWithText(FilledButton, 'Change MPIN'));
      await tester.pump();
    }

    await attempt('1234', '1234');
    expect(find.text('Must be different from the current MPIN'), findsOneWidget);
    await attempt('1234', '7777');
    expect(find.textContaining('all the same digit'), findsOneWidget);
    await attempt('1234', '3456');
    expect(find.textContaining('a sequence'), findsOneWidget);
    await attempt('1234', '8051');
    expect(saved, '8051');
  });

  testWidgets('welcome screen shows bank name and actions', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
    expect(find.text('Sahyadri Bank'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Open a new account'), findsOneWidget);
  });
}
