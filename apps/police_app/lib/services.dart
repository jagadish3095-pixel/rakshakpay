import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

/// App-wide objects, created once.
final api = RakshakApi('police');
final location = LocationService(api);
final live = LiveUpdates(api);
final savedLogins = SavedLogins(api);

const kNavy = Color(0xFF0D2B5E);
const kAmber = Color(0xFFFFB300);

ThemeData policeTheme() => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: kNavy, primary: kNavy, secondary: kAmber),
      appBarTheme: const AppBarTheme(backgroundColor: kNavy, foregroundColor: Colors.white),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    );

/// Colour for each account role in a money trail.
Color roleColor(String role) => switch (role) {
      'VICTIM' => Colors.blue.shade700,
      'MULE' => Colors.red.shade700,
      'MERCHANT' => Colors.green.shade700,
      'EXCHANGE' => Colors.purple.shade600,
      _ => Colors.grey,
    };

String roleLabel(String role) => switch (role) {
      'VICTIM' => 'Victim',
      'MULE' => 'Suspected mule',
      'MERCHANT' => 'Merchant (protected)',
      'EXCHANGE' => 'Crypto exchange',
      _ => role,
    };

/// Mixin for screens that reload when anything changes on the server (debounced).
mixin LiveRefresh<T extends StatefulWidget> on State<T> {
  StreamSubscription<String>? _liveSub;
  Timer? _debounce;

  Future<void> reload();

  void startLive() {
    live.start();
    _liveSub = live.changes.listen((_) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 800), reload);
    });
  }

  @override
  void dispose() {
    _liveSub?.cancel();
    _debounce?.cancel();
    super.dispose();
  }
}

/// A small coloured statistic box for dashboards.
class StatTile extends StatelessWidget {
  const StatTile(this.label, this.value, {super.key, this.color = kNavy, this.icon});
  final String label, value;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (icon != null) Icon(icon, size: 18, color: color),
              if (icon != null) const SizedBox(width: 6),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54))),
            ]),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ]),
        ),
      ),
    );
  }
}
