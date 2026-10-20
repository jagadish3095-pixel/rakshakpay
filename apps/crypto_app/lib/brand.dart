import 'package:flutter/material.dart';

/// CoinVault colours: dark background, teal and gold (a made-up exchange brand).
const kTeal = Color(0xFF14B8A6);
const kGold = Color(0xFFF5B301);
const kBg = Color(0xFF0B1418);
const kCard = Color(0xFF14232A);

ThemeData coinVaultTheme() => ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: kBg,
      colorScheme: ColorScheme.fromSeed(
          seedColor: kTeal, brightness: Brightness.dark, primary: kTeal, secondary: kGold, surface: kCard),
      appBarTheme: const AppBarTheme(backgroundColor: kBg, foregroundColor: Colors.white, elevation: 0),
      cardTheme: const CardThemeData(color: kCard),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    );

class CoinVaultLogo extends StatelessWidget {
  const CoinVaultLogo({super.key, this.size = 64});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        Icon(Icons.hexagon, size: size, color: kGold),
        Text('C', style: TextStyle(fontSize: size * 0.45, fontWeight: FontWeight.w900, color: kBg)),
      ]),
    );
  }
}

/// Display details for each coin.
class CoinInfo {
  const CoinInfo(this.symbol, this.name, this.sign, this.color);
  final String symbol, name, sign;
  final Color color;

  static const all = {
    'BTC': CoinInfo('BTC', 'Bitcoin', '₿', Color(0xFFF7931A)),
    'ETH': CoinInfo('ETH', 'Ethereum', 'Ξ', Color(0xFF8C8CF0)),
    'USDT': CoinInfo('USDT', 'Tether USD', '₮', Color(0xFF26A17B)),
  };
}

class CoinIcon extends StatelessWidget {
  const CoinIcon(this.symbol, {super.key, this.size = 40});
  final String symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = CoinInfo.all[symbol]!;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: c.color,
      child: Text(c.sign, style: TextStyle(color: Colors.white, fontSize: size * 0.5, fontWeight: FontWeight.bold)),
    );
  }
}
