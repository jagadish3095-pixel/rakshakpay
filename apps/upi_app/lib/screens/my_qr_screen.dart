import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rakshak_core/rakshak_core.dart';


/// Shows your UPI QR code so others can scan and pay you.
class MyQrScreen extends StatefulWidget {
  const MyQrScreen({super.key, required this.profile});
  final UpiProfile profile;

  @override
  State<MyQrScreen> createState() => _MyQrScreenState();
}

class _MyQrScreenState extends State<MyQrScreen> {
  late UpiVpa _vpa = widget.profile.vpas.first;
  int? _amount;

  Future<void> _askAmount() async {
    final c = TextEditingController();
    final paise = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Request a fixed amount')),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: '₹ '),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, parsePaise(c.text)), child: Text(tr('Set'))),
        ],
      ),
    );
    if (paise != null) setState(() => _amount = paise);
  }

  @override
  Widget build(BuildContext context) {
    final bank = BankBrand.byCode(_vpa.bankCode);
    final data = buildUpiUri(vpa: _vpa.address, name: _vpa.displayName, amountPaise: _amount);
    return Scaffold(
      appBar: AppBar(title: Text(tr('My QR code'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (widget.profile.vpas.length > 1)
            DropdownButtonFormField<UpiVpa>(
              initialValue: _vpa,
              isExpanded: true,
              decoration: InputDecoration(labelText: tr('Receive money in')),
              items: [
                for (final v in widget.profile.vpas)
                  DropdownMenuItem(value: v, child: Text('${BankBrand.byCode(v.bankCode).name} • ${v.address}')),
              ],
              onChanged: (v) => setState(() => _vpa = v!),
            ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const RakshakLogo(size: 28),
                  const SizedBox(width: 8),
                  Text(_vpa.isMerchant ? tr('Pay this shop') : tr('Scan to pay'),
                      style: Theme.of(context).textTheme.titleMedium),
                ]),
                const SizedBox(height: 12),
                QrImageView(data: data, size: 240, backgroundColor: Colors.white),
                const SizedBox(height: 12),
                Text(_vpa.displayName, style: Theme.of(context).textTheme.titleLarge),
                Text(_vpa.address),
                Text(bank.name, style: TextStyle(color: bank.color)),
                if (_amount != null) ...[
                  const SizedBox(height: 8),
                  Text(tr('Amount: {amount}', {'amount': rupees(_amount!)}), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _vpa.address));
                  showInfo(context, tr('UPI ID copied'));
                },
                icon: const Icon(Icons.copy),
                label: Text(tr('Copy UPI ID')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _amount == null
                  ? OutlinedButton.icon(
                      onPressed: _askAmount, icon: const Icon(Icons.currency_rupee), label: Text(tr('Set amount')))
                  : OutlinedButton.icon(
                      onPressed: () => setState(() => _amount = null),
                      icon: const Icon(Icons.clear),
                      label: Text(tr('Clear amount'))),
            ),
          ]),
        ],
      ),
    );
  }
}
