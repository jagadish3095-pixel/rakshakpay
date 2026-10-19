import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The look of one of the 5 banks. The same code builds 5 different apps;
/// which bank you get depends on the Flutter "flavor" used to build it.
class BankBrand {
  const BankBrand(this.flavor, this.code, this.name, this.color, this.tagline, this.icon);

  final String flavor, code, name, tagline;
  final Color color;
  final IconData icon;

  static const all = [
    BankBrand('sahyadri', 'SAHY', 'Sahyadri Bank', Color(0xFF1B8A5A), 'Strong like the Western Ghats', Icons.landscape),
    BankBrand('ganga', 'GANG', 'Ganga Bank', Color(0xFF1E5BB8), 'Flowing with trust', Icons.water),
    BankBrand('kaveri', 'KAVR', 'Kaveri Bank', Color(0xFF6B3FA0), 'Nurturing every rupee', Icons.spa),
    BankBrand('narmada', 'NARM', 'Narmada Bank', Color(0xFFD9731A), 'Banking at the heart of India', Icons.wb_sunny),
    BankBrand('godavari', 'GODA', 'Godavari Bank', Color(0xFFC62F3B), 'Deep roots, wide reach', Icons.account_balance),
  ];

  /// Android builds use --flavor; web/test builds can pass --dart-define=BANK=ganga.
  static BankBrand current() {
    final flavor = appFlavor ?? const String.fromEnvironment('BANK', defaultValue: 'sahyadri');
    return all.firstWhere((b) => b.flavor == flavor, orElse: () => all.first);
  }
}

class BankLogo extends StatelessWidget {
  const BankLogo(this.brand, {super.key, this.size = 56});
  final BankBrand brand;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: brand.color, width: size / 14),
      ),
      child: Icon(brand.icon, color: brand.color, size: size * 0.55),
    );
  }
}
