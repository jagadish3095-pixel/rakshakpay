import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';

/// Change the app passcode and UPI PINs, or reset a forgotten UPI PIN with the debit card.
class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key, required this.profile});
  final UpiProfile profile;

  @override
  Widget build(BuildContext context) {
    Future<void> open(Widget s) => Navigator.push(context, MaterialPageRoute(builder: (_) => s));
    return Scaffold(
      appBar: AppBar(title: Text(tr('Security'))),
      body: ListView(children: [
        ListTile(
          leading: const Icon(Icons.lock),
          title: Text(tr('Change app passcode')),
          subtitle: Text(tr('4 digits to open RakshakPay (also used by RakshakPay Business)')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => open(ChangeSecretScreen(
            title: tr('Change app passcode'),
            what: 'passcode',
            submit: (current, next) async {
              await api.post('/api/upi/passcode', {'current': current, 'new': next});
              await savedLogins.updatePassword(profile.mobile, next);
            },
          )),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(tr('UPI PIN (for each bank account)'), style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        for (final v in profile.vpas)
          Card(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Column(children: [
              ListTile(
                leading: BankLogo(BankBrand.byCode(v.bankCode), size: 36),
                title: Text(BankBrand.byCode(v.bankCode).name),
                subtitle: Text('${tr('A/c {account}', {'account': v.accountNoMasked})} • ${v.address}'),
              ),
              OverflowBar(alignment: MainAxisAlignment.end, children: [
                TextButton(
                  onPressed: () => open(ChangeSecretScreen(
                    title: tr('Change UPI PIN'),
                    what: 'UPI PIN',
                    help: tr('{bank} A/c {account}',
                        {'bank': BankBrand.byCode(v.bankCode).name, 'account': v.accountNoMasked}),
                    submit: (current, next) =>
                        api.post('/api/upi/vpas/${v.address}/pin', {'current': current, 'new': next}),
                  )),
                  child: Text(tr('Change UPI PIN')),
                ),
                TextButton(
                  onPressed: () => open(_ForgotUpiPinScreen(vpa: v)),
                  child: Text(tr('Forgot UPI PIN?')),
                ),
              ]),
            ]),
          ),
      ]),
    );
  }
}

/// Reset the UPI PIN with the debit card (last 6 digits + expiry), like real UPI apps.
class _ForgotUpiPinScreen extends StatefulWidget {
  const _ForgotUpiPinScreen({required this.vpa});
  final UpiVpa vpa;

  @override
  State<_ForgotUpiPinScreen> createState() => _ForgotUpiPinScreenState();
}

class _ForgotUpiPinScreenState extends State<_ForgotUpiPinScreen> {
  final _form = GlobalKey<FormState>();
  final _last6 = TextEditingController();
  final _expiry = TextEditingController();
  final _pin = TextEditingController();
  final _pin2 = TextEditingController();
  bool _busy = false;

  Future<void> _reset() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await api.post('/api/upi/vpas/${widget.vpa.address}/pin',
          {'new': _pin.text, 'card_last6': _last6.text, 'card_expiry': _expiry.text});
      if (!mounted) return;
      showInfo(context, tr('New UPI PIN set'));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bank = BankBrand.byCode(widget.vpa.bankCode);
    TextFormField pinField(TextEditingController c, String label, String? Function(String?) v) => TextFormField(
          controller: c,
          obscureText: true,
          maxLength: 4,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: label),
          validator: v,
        );
    return Scaffold(
      appBar: AppBar(title: Text(tr('Reset UPI PIN'))),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text('${tr('{bank} A/c {account}', {'bank': bank.name, 'account': widget.vpa.accountNoMasked})}\n'
              '${tr('Enter your debit card details (see "Debit card" in your bank app).')}'),
          const SizedBox(height: 12),
          TextFormField(
            controller: _last6,
            maxLength: 6,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: tr('Last 6 digits of debit card')),
            validator: (v) => (v?.length ?? 0) == 6 ? null : tr('Enter 6 digits'),
          ),
          TextFormField(
            controller: _expiry,
            maxLength: 5,
            keyboardType: TextInputType.number,
            inputFormatters: [ExpiryFormatter()],
            decoration: InputDecoration(labelText: tr('Expiry (valid thru)'), hintText: 'MM/YY'),
            validator: (v) => RegExp(r'^(0[1-9]|1[0-2])/\d{2}$').hasMatch(v ?? '') ? null : tr('Format MM/YY'),
          ),
          pinField(_pin, tr('New 4-digit UPI PIN'),
              (v) => RegExp(r'^\d{4}$').hasMatch(v ?? '') ? null : tr('Enter 4 digits')),
          pinField(_pin2, tr('Confirm UPI PIN'), (v) => v != _pin.text ? tr('Does not match') : null),
          FilledButton(
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            onPressed: _busy ? null : _reset,
            child: Text(_busy ? tr('Saving…') : tr('Set new UPI PIN')),
          ),
        ]),
      ),
    );
  }
}
