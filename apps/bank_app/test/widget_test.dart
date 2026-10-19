import 'package:bank_app/brand.dart';
import 'package:bank_app/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('five distinct banks', () {
    expect(BankBrand.all.length, 5);
    expect(BankBrand.all.map((b) => b.code).toSet().length, 5);
  });

  testWidgets('welcome screen shows bank name and actions', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
    expect(find.text('Sahyadri Bank'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Open a new account'), findsOneWidget);
  });
}
