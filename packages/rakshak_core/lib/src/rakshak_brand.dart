import 'package:flutter/material.dart';

/// RakshakPay colours: indigo (trust) with a saffron accent.
const kIndigo = Color(0xFF3B2A8C);
const kSaffron = Color(0xFFFF8F1F);

ThemeData rakshakTheme([Brightness brightness = Brightness.light]) =>
    brandTheme(kIndigo, brightness, secondary: kSaffron);

/// Day or night theme in an app's brand colour. The app bar keeps the brand colour (darker at night).
ThemeData brandTheme(Color seed, Brightness brightness, {Color? secondary}) {
  final light = brightness == Brightness.light;
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
        seedColor: seed, brightness: brightness, primary: light ? seed : null, secondary: light ? secondary : null),
    appBarTheme: AppBarTheme(
        backgroundColor: light ? seed : Color.lerp(seed, Colors.black, 0.45), foregroundColor: Colors.white),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
  );
}

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
