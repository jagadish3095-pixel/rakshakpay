import 'package:flutter/services.dart';
import 'package:rakshak_core/rakshak_core.dart';

export 'package:rakshak_core/rakshak_core.dart' show BankBrand, BankLogo;

/// Which of the 5 banks this app is. The same code builds 5 different apps;
/// Android builds use --flavor, web/test builds can pass --dart-define=BANK=ganga.
BankBrand currentBrand() {
  final flavor = appFlavor ?? const String.fromEnvironment('BANK', defaultValue: 'sahyadri');
  return BankBrand.all.firstWhere((b) => b.flavor == flavor, orElse: () => BankBrand.all.first);
}
