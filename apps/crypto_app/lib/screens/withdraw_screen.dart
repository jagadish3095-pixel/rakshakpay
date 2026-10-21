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
    if (amount == null) return showError(context, tr('Enter an amount'));
    final pin = await askPin(context,
        title: tr('Enter CoinVault PIN'), subtitle: tr('Withdraw {amount} to your bank', {'amount': rupees(amount)}));
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
      appBar: AppBar(title: Text(tr('Withdraw to bank'))),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text(tr('Available: {amount}', {'amount': rupees(p.inr)}), style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 12),
        TextField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: tr('Amount'),
            prefixText: '₹ ',
            suffixIcon: TextButton(
              onPressed: () => _amount.text = (p.inr / 100).toStringAsFixed(2),
              child: Text(tr('MAX')),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.account_balance),
          title: Text(tr('To {bank}', {'bank': p.bankName})),
          subtitle: Text(tr('A/c {account} (your KYC account) • IMPS', {'account': p.bankAccountMasked})),
        ),
        FilledButton(
          style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
          onPressed: _busy ? null : _withdraw,
          child: Text(_busy ? tr('Sending…') : tr('Withdraw')),
        ),
      ]),
    );
  }
}
