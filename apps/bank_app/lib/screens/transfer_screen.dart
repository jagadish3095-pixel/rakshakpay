import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';

/// IMPS / NEFT transfer to any account in any of the 5 banks.
class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key, required this.account});
  final Account account;

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _form = GlobalKey<FormState>();
  final _accNo = TextEditingController();
  final _accNo2 = TextEditingController();
  final _ifsc = TextEditingController();
  final _amount = TextEditingController();
  final _remark = TextEditingController();
  String _mode = 'IMPS';
  Map<String, dynamic>? _payee;
  bool _busy = false;

  Future<void> _verifyPayee() async {
    if (_accNo.text != _accNo2.text) return showError(context, tr('Account numbers do not match'));
    setState(() => _busy = true);
    try {
      final res = await api.get('/api/lookup', {'account_no': _accNo.text, 'ifsc': _ifsc.text});
      setState(() => _payee = res);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    final amount = parsePaise(_amount.text)!;
    final warning = _payee!['warning'] as String?;
    if (warning != null && !await confirmPayMule(context, warning)) return;
    if (!mounted) return;
    // Location is mandatory: no GPS position, no payment.
    setState(() => _busy = true);
    final loc = await location.requireForPayment(context);
    if (mounted) setState(() => _busy = false);
    if (loc == null || !mounted) return;
    final pin = await askPin(context,
        title: tr('Enter MPIN'),
        subtitle: tr('Send {amount} to {name} via {mode}',
            {'amount': rupees(amount), 'name': _payee!['name'], 'mode': _mode}));
    if (pin == null) return;
    setState(() => _busy = true);
    try {
      final res = await api.post('/api/transfers', {
        'from_account': widget.account.accountNo,
        'to_account': _accNo.text,
        'to_ifsc': _ifsc.text,
        'amount': amount,
        'mode': _mode,
        'mpin': pin,
        'remark': _remark.text,
        'location': loc.toJson(),
        'acknowledge_warning': warning != null,
      });
      if (!mounted) return;
      await Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => _SuccessScreen(res: res, payee: _payee!, amount: amount, place: loc.label)));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final verified = _payee != null;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Send money'))),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: Text(tr('From A/c {account}', {'account': widget.account.accountNo})),
                subtitle: Text(tr('Available {amount}', {'amount': rupees(widget.account.availableBalance)})),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _accNo,
              readOnly: verified,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: tr('Beneficiary account number')),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _accNo2,
              readOnly: verified,
              obscureText: !verified,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: tr('Re-enter account number')),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ifsc,
              readOnly: verified,
              maxLength: 11,
              inputFormatters: [UpperCaseFormatter()],
              decoration: InputDecoration(labelText: tr('IFSC code'), hintText: tr('e.g. {ifsc}', {'ifsc': 'GNGA0000005'})),
            ),
            if (!verified)
              FilledButton.tonal(onPressed: _busy ? null : _verifyPayee, child: Text(tr('Verify beneficiary')))
            else ...[
              Card(
                color: softBg(context, Colors.green),
                child: ListTile(
                  leading: const Icon(Icons.verified_user, color: Colors.green),
                  title: Text(_payee!['business_name'].toString().isNotEmpty
                      ? '${_payee!['business_name']} (${_payee!['name']})'
                      : _payee!['name']),
                  subtitle: Text('${_payee!['bank']} • ${_payee!['branch']}'),
                  trailing: TextButton(onPressed: () => setState(() => _payee = null), child: Text(tr('Change'))),
                ),
              ),
              if (_payee!['warning'] != null) MuleWarningCard(_payee!['warning']),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: tr('Amount'), prefixText: '₹ '),
                validator: (v) => parsePaise(v ?? '') == null ? tr('Enter a valid amount') : null,
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'IMPS', label: Text(tr('IMPS (instant)'))),
                  const ButtonSegment(value: 'NEFT', label: Text('NEFT')),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _remark, maxLength: 60, decoration: InputDecoration(labelText: tr('Remark (optional)'))),
              FilledButton.icon(
                style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                onPressed: _busy ? null : _send,
                icon: const Icon(Icons.send),
                label: Text(_busy ? tr('Sending…') : tr('Pay now')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SuccessScreen extends StatelessWidget {
  const _SuccessScreen({required this.res, required this.payee, required this.amount, required this.place});
  final Map<String, dynamic> res;
  final Map<String, dynamic> payee;
  final int amount;
  final String place;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade700,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Spacer(),
            const Icon(Icons.check_circle, color: Colors.white, size: 96),
            const SizedBox(height: 16),
            Text(rupees(amount), style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
            Text(tr('sent to {name}', {
                  'name': (payee['business_name'] as String).isNotEmpty ? payee['business_name'] : payee['name']
                }),
                style: const TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 24),
            Card(
              child: Column(children: [
                ListTile(dense: true, title: Text(tr('UTR / Reference')), trailing: SelectableText(res['utr'])),
                ListTile(dense: true, title: Text(tr('Mode')), trailing: Text(res['channel'])),
                ListTile(dense: true, title: Text(tr('Date')), trailing: Text(formatDateTime(res['date']))),
                ListTile(dense: true, title: Text(tr('Location')), trailing: Text(place)),
                ListTile(
                    dense: true,
                    title: Text(tr('Available balance')),
                    trailing: Text(rupees(res['available_balance']))),
              ]),
            ),
            const Spacer(),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.green.shade800),
              onPressed: () => Navigator.pop(context),
              child: Text(tr('Done')),
            ),
          ]),
        ),
      ),
    );
  }
}
