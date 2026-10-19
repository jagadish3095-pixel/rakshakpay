import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';

class CardScreen extends StatefulWidget {
  const CardScreen({super.key, required this.account});
  final Account account;

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  late bool _blocked = widget.account.cardBlocked;
  bool _showNumber = false;

  Future<void> _toggle(bool block) async {
    try {
      await api.post('/api/accounts/${widget.account.accountNo}/card', {'blocked': block});
      setState(() => _blocked = block);
      if (mounted) showInfo(context, block ? 'Card blocked' : 'Card unblocked');
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.account.cardNo;
    final number = _showNumber
        ? '${n.substring(0, 4)}  ${n.substring(4, 8)}  ${n.substring(8, 12)}  ${n.substring(12)}'
        : 'XXXX  XXXX  XXXX  ${n.substring(12)}';
    final validThru = widget.account.cardExpiry; // needed to set a UPI PIN

    return Scaffold(
      appBar: AppBar(title: const Text('Debit card')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 1.586,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: _blocked
                      ? [Colors.grey.shade600, Colors.grey.shade800]
                      : [brand.color, Color.lerp(brand.color, Colors.black, 0.55)!],
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(brand.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Icon(brand.icon, color: Colors.white70),
                ]),
                const Spacer(),
                const Icon(Icons.sim_card, color: Colors.amber, size: 36),
                const SizedBox(height: 8),
                Text(number, style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                Row(children: [
                  Text(widget.account.holderName.toUpperCase(), style: const TextStyle(color: Colors.white)),
                  const Spacer(),
                  Text('VALID THRU $validThru', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
                if (_blocked)
                  const Text('BLOCKED', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
          SwitchListTile(
            title: const Text('Show card number'),
            value: _showNumber,
            onChanged: (v) => setState(() => _showNumber = v),
          ),
          SwitchListTile(
            title: const Text('Block card'),
            subtitle: const Text('Stops ATM withdrawals with this card'),
            value: _blocked,
            onChanged: _toggle,
          ),
        ],
      ),
    );
  }
}
