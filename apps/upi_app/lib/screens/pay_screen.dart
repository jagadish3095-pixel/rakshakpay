import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';

/// Pay a UPI ID or mobile number. Opened directly, or from a scanned QR code.
class PayScreen extends StatefulWidget {
  const PayScreen({super.key, required this.profile, this.to, this.amountPaise});
  final UpiProfile profile;
  final String? to;
  final int? amountPaise; // fixed amount from a QR code

  @override
  State<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends State<PayScreen> {
  late final _to = TextEditingController(text: widget.to);
  late final _amount = TextEditingController(
      text: widget.amountPaise == null ? '' : (widget.amountPaise! / 100).toStringAsFixed(2));
  final _note = TextEditingController();
  late UpiVpa _from = widget.profile.vpas.first;
  Map<String, dynamic>? _payee;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.to != null) _verify();
  }

  Future<void> _verify() async {
    if (_to.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final res = await api.get('/api/upi/resolve', {'to': _to.text.trim()});
      setState(() => _payee = res);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pay() async {
    final amount = parsePaise(_amount.text);
    if (amount == null) return showError(context, 'Enter a valid amount');
    final pin = await askPin(context,
        title: 'Enter UPI PIN', subtitle: 'Pay ${rupees(amount)} to ${_payee!['name']}\nfrom ${_from.address}');
    if (pin == null) return;
    setState(() => _busy = true);
    try {
      final loc = await location.current();
      final res = await api.post('/api/upi/pay', {
        'from_vpa': _from.address,
        'to': _payee!['vpa'],
        'amount': amount,
        'upi_pin': pin,
        'remark': _note.text,
        'location': loc.toJson(),
      });
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => PaySuccessScreen(res: res, amount: amount, fromVpa: _from.address, place: loc.label)));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final payee = _payee;
    return Scaffold(
      appBar: AppBar(title: const Text('Pay')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (payee == null) ...[
            TextField(
              controller: _to,
              autofocus: widget.to == null,
              decoration: const InputDecoration(
                labelText: 'UPI ID or mobile number',
                hintText: 'e.g. ravi6780@ganga or 9123456780',
                prefixIcon: Icon(Icons.alternate_email),
              ),
              onSubmitted: (_) => _verify(),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _busy ? null : _verify, child: Text(_busy ? 'Checking…' : 'Verify')),
          ] else ...[
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: kSaffron,
                  child: Icon(payee['is_merchant'] == true ? Icons.storefront : Icons.person, color: Colors.white),
                ),
                title: Row(children: [
                  Flexible(child: Text(payee['name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(width: 6),
                  const Icon(Icons.verified, size: 18, color: Colors.green),
                ]),
                subtitle: Text('${payee['vpa']}\n${payee['bank']}'
                    '${payee['is_merchant'] == true ? ' • Verified merchant' : ''}'),
                isThreeLine: true,
                trailing: widget.to == null
                    ? TextButton(onPressed: () => setState(() => _payee = null), child: const Text('Change'))
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amount,
              readOnly: widget.amountPaise != null,
              autofocus: widget.amountPaise == null,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(prefixText: '₹ ', hintText: '0', border: InputBorder.none),
            ),
            TextField(
              controller: _note,
              maxLength: 60,
              decoration: const InputDecoration(labelText: 'Add a note (optional)'),
            ),
            const SizedBox(height: 8),
            if (widget.profile.vpas.length > 1)
              DropdownButtonFormField<UpiVpa>(
                initialValue: _from,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Pay from'),
                items: [
                  for (final v in widget.profile.vpas)
                    DropdownMenuItem(
                      value: v,
                      child: Text('${BankBrand.byCode(v.bankCode).name} • ${v.accountNoMasked}'),
                    ),
                ],
                onChanged: (v) => setState(() => _from = v!),
              )
            else
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: BankLogo(BankBrand.byCode(_from.bankCode), size: 36),
                title: Text('Pay from ${BankBrand.byCode(_from.bankCode).name}'),
                subtitle: Text('A/c ${_from.accountNoMasked} • ${_from.address}'),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
              onPressed: _busy ? null : _pay,
              icon: const Icon(Icons.lock),
              label: Text(_busy ? 'Paying…' : 'Pay securely'),
            ),
          ],
        ],
      ),
    );
  }
}

class PaySuccessScreen extends StatelessWidget {
  const PaySuccessScreen({super.key, required this.res, required this.amount, required this.fromVpa, required this.place});
  final Map<String, dynamic> res;
  final int amount;
  final String fromVpa, place;

  @override
  Widget build(BuildContext context) {
    Widget row(String k, String v) => ListTile(dense: true, title: Text(k), trailing: Text(v));
    return Scaffold(
      backgroundColor: Colors.green.shade700,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Spacer(),
            const Icon(Icons.check_circle, color: Colors.white, size: 96),
            const SizedBox(height: 12),
            Text(rupees(amount), style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
            Text('paid to ${res['payee_name']}', style: const TextStyle(color: Colors.white, fontSize: 18)),
            Text(res['payee_vpa'], style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            Card(
              child: Column(children: [
                row('UPI Ref (UTR)', res['utr']),
                row('From', fromVpa),
                row('Date', formatDateTime(res['date'])),
                row('Location', place),
              ]),
            ),
            const Spacer(),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.green.shade800),
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ]),
        ),
      ),
    );
  }
}
