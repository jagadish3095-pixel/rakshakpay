import 'package:bank_app/brand.dart';
import 'package:bank_app/screens/lock_screen.dart';
import 'package:bank_app/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  testWidgets('welcome screen shows bank name and actions', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
    expect(find.text('Sahyadri Bank'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Open a new account'), findsOneWidget);
  });
}
