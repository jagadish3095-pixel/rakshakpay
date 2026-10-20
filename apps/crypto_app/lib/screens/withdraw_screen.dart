import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../models.dart';
import '../services.dart';

/// Withdraw rupees to the KYC bank account (sent by IMPS).
class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key, required this.profile});
  final CryptoProfile profile;

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _amount = TextEditingController();
  bool _busy = false;

  Future<void> _withdraw() async {
    final amount = parsePaise(_amount.text);
    if (amount == null) return showError(context, 'Enter an amount');
    final pin = await askPin(context, title: 'Enter CoinVault PIN', subtitle: 'Withdraw ${rupees(amount)} to your bank');
    if (pin == null) return;
    setState(() => _busy = true);
    try {
      final res = await api.post('/api/crypto/withdraw-inr', {'amount': amount, 'pin': pin});
      if (!mounted) return;
      showInfo(context, '${res['message']} (UTR ${res['utr']})');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Withdraw to bank')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text('Available: ${rupees(p.inr)}', style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 12),
        TextField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixText: '₹ ',
            suffixIcon: TextButton(
              onPressed: () => _amount.text = (p.inr / 100).toStringAsFixed(2),
              child: const Text('MAX'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.account_balance),
          title: Text('To ${p.bankName}'),
          subtitle: Text('A/c ${p.bankAccountMasked} (your KYC account) • IMPS'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
          onPressed: _busy ? null : _withdraw,
          child: Text(_busy ? 'Sending…' : 'Withdraw'),
        ),
      ]),
    );
  }
}
