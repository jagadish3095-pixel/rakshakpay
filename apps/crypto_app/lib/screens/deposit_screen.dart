import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rakshak_core/rakshak_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../brand.dart';
import '../models.dart';

/// Add rupees: pay CoinVault's UPI ID from your OWN bank account.
/// The "Pay with RakshakPay" button opens the UPI app with everything filled in.
class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key, required this.profile});
  final CryptoProfile profile;

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final _amount = TextEditingController(text: '5000');

  String get _uri => buildUpiUri(
      vpa: widget.profile.depositVpa, name: widget.profile.depositName, amountPaise: parsePaise(_amount.text));

  Future<void> _payWithUpiApp() async {
    if (parsePaise(_amount.text) == null) return showError(context, tr('Enter an amount'));
    final ok = await launchUrl(Uri.parse(_uri), mode: LaunchMode.externalApplication);
    if (!ok && mounted) showError(context, tr('No UPI app found. Install RakshakPay.'));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Deposit rupees'))),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        TextField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          decoration: InputDecoration(labelText: tr('Amount'), prefixText: '₹ '),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Card(
          color: softBg(context, Colors.amber),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(tr(
                'Pay only from your own bank account: {bank} {account}.\n'
                'Payments from anyone else\'s account are refunded automatically.',
                {'bank': p.bankName, 'account': p.bankAccountMasked})),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
          onPressed: _payWithUpiApp,
          icon: const Icon(Icons.open_in_new),
          label: Text(tr('Pay with RakshakPay')),
        ),
        const SizedBox(height: 24),
        Center(child: Text(tr('or scan with any UPI app'), style: TextStyle(color: muted(context)))),
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: QrImageView(data: _uri, size: 220),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: p.depositVpa));
              showInfo(context, tr('UPI ID copied'));
            },
            icon: Icon(Icons.copy, color: goldText(context)),
            label: Text(p.depositVpa, style: TextStyle(color: goldText(context), fontSize: 16)),
          ),
        ),
        const SizedBox(height: 8),
        Text(tr('After paying, come back here. Your INR wallet updates automatically.'),
            textAlign: TextAlign.center, style: TextStyle(color: muted(context))),
      ]),
    );
  }
}
