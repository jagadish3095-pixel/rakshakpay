import 'package:flutter/material.dart';

/// RakshakPay colours: indigo (trust) with a saffron accent.
const kIndigo = Color(0xFF3B2A8C);
const kSaffron = Color(0xFFFF8F1F);

ThemeData rakshakTheme() => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: kIndigo, primary: kIndigo, secondary: kSaffron),
      appBarTheme: const AppBarTheme(backgroundColor: kIndigo, foregroundColor: Colors.white),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    );

/// Shield with a rupee sign: "Rakshak" means protector.
class RakshakLogo extends StatelessWidget {
  const RakshakLogo({super.key, this.size = 64, this.onDark = false});
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        Icon(Icons.shield, size: size, color: onDark ? Colors.white : kIndigo),
        Padding(
          padding: EdgeInsets.only(bottom: size * 0.08),
          child: Text('₹',
              style: TextStyle(
                  fontSize: size * 0.42, fontWeight: FontWeight.bold, color: onDark ? kIndigo : kSaffron)),
        ),
      ]),
    );
  }
}
