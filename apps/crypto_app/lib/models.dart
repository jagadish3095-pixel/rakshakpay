// CoinVault data from the server. Rupees are in paise; coins in 1/100,000,000 units.

import 'package:rakshak_core/rakshak_core.dart';

const kUnits = 100000000;

/// 12345678 units -> "0.12345678" (trailing zeros removed).
String formatQty(int units) {
  final s = (units / kUnits).toStringAsFixed(8);
  return s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
}

/// "0.0005" -> 50000 units. Null if invalid.
int? parseQty(String text) {
  final v = double.tryParse(text.trim());
  if (v == null || v <= 0) return null;
  return (v * kUnits).round();
}

class Holding {
  Holding.fromJson(Map<String, dynamic> j)
      : asset = j['asset'],
        quantity = j['quantity'],
        price = j['price'],
        value = j['value'];
  final String asset;
  final int quantity, price, value;
}

class CryptoProfile {
  CryptoProfile.fromJson(Map<String, dynamic> j)
      : mobile = j['mobile'],
        name = j['name'],
        panMasked = j['pan_masked'],
        bankName = j['bank']['name'],
        bankAccountMasked = j['bank']['account_no_masked'],
        inr = j['inr'],
        totalValue = j['total_value'],
        holdings = [for (final h in j['holdings']) Holding.fromJson(h)],
        depositVpa = j['deposit_vpa'],
        depositName = j['deposit_name'];

  final String mobile, name, panMasked, bankName, bankAccountMasked, depositVpa, depositName;
  final int inr, totalValue;
  final List<Holding> holdings;

  Holding holding(String asset) => holdings.firstWhere((h) => h.asset == asset);
}

class PriceTick {
  PriceTick.fromJson(Map<String, dynamic> j)
      : asset = j['asset'],
        price = j['price'],
        changePct = (j['change_pct'] as num).toDouble();
  final String asset;
  final int price;
  final double changePct;
}

class ExchangeEntry {
  ExchangeEntry.fromJson(Map<String, dynamic> j)
      : kind = j['kind'],
        asset = j['asset'],
        quantity = j['quantity'],
        inr = j['inr'],
        price = j['price'],
        address = j['address'] ?? '',
        utr = j['utr'] ?? '',
        date = j['date'];
  final String kind, asset, address, utr, date;
  final int quantity, inr;
  final int? price;

  String get title => switch (kind) {
        'DEPOSIT' => tr('Deposited rupees'),
        'BUY' => tr('Bought {asset}', {'asset': asset}),
        'SELL' => tr('Sold {asset}', {'asset': asset}),
        'WITHDRAW_INR' => tr('Withdrew to bank'),
        'WITHDRAW_CRYPTO' => tr('Sent {asset} to outside wallet', {'asset': asset}),
        _ => kind,
      };
}
