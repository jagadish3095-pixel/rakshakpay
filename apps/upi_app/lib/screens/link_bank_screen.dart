import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';

/// Link a bank account: pick bank -> the bank finds your account by mobile ->
/// verify debit card (last 6 digits + expiry) -> set UPI PIN.
class LinkBankScreen extends StatefulWidget {
  const LinkBankScreen({super.key});

  @override
  State<LinkBankScreen> createState() => _LinkBankScreenState();
}

class _LinkBankScreenState extends State<LinkBankScreen> {
  BankBrand? _bank;
  List<Map<String, dynamic>>? _accounts;
  Map<String, dynamic>? _account;
  bool _busy = false;

  final _form = GlobalKey<FormState>();
  final _last6 = TextEditingController();
  final _expiry = TextEditingController();
  final _pin = TextEditingController();
  final _pin2 = TextEditingController();

  Future<void> _pickBank(BankBrand bank) async {
    setState(() {
      _bank = bank;
      _accounts = null;
      _busy = true;
    });
    try {
      final res = await api.get('/api/upi/banks/${bank.code}/accounts');
      setState(() => _accounts = (res['accounts'] as List).cast<Map<String, dynamic>>());
    } catch (e) {
      if (mounted) showError(context, e);
      setState(() => _bank = null);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _link() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final res = await api.post('/api/upi/link', {
        'account_no': _account!['account_no'],
        'card_last6': _last6.text,
        'card_expiry': _expiry.text,
        'upi_pin': _pin.text,
      });
      restartLive();
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 56),
          title: Text(tr('Bank account linked')),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(tr('Your UPI ID is')),
            const SizedBox(height: 6),
            SelectableText(res['vpa']['address'],
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(tr('Remember your UPI PIN. You need it for every payment.'), textAlign: TextAlign.center),
          ]),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Done')))],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Link bank account'))),
      body: _busy && _accounts == null
          ? const Center(child: CircularProgressIndicator())
          : _account != null
              ? _cardStep()
              : _bank != null
                  ? _accountStep()
                  : _bankStep(),
    );
  }

  Widget _bankStep() => ListView(padding: const EdgeInsets.all(16), children: [
        Text(tr('Select your bank'), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        for (final b in BankBrand.all)
          Card(
            child: ListTile(
              leading: BankLogo(b, size: 40),
              title: Text(b.name),
              subtitle: Text('@${b.upiHandle}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _pickBank(b),
            ),
          ),
      ]);

  Widget _accountStep() {
    final accounts = _accounts ?? [];
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        BankLogo(_bank!, size: 40),
        const SizedBox(width: 12),
        Expanded(child: Text(_bank!.name, style: Theme.of(context).textTheme.titleLarge)),
        TextButton(onPressed: () => setState(() => _bank = null), child: Text(tr('Change'))),
      ]),
      const SizedBox(height: 16),
      if (accounts.isEmpty)
        Card(
          color: softBg(context, Colors.orange),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(tr('No {bank} account is registered with your mobile number.\n\n'
                'Open an account in the {bank} app using the same mobile number, then try again.',
                {'bank': _bank!.name})),
          ),
        )
      else ...[
        Text(tr('Accounts found with your mobile number:')),
        for (final a in accounts)
          Card(
            child: ListTile(
              enabled: a['already_linked'] != true,
              leading: Icon(a['account_type'] == 'CURRENT' ? Icons.storefront : Icons.savings),
              title: Text(tr('A/c {account}', {'account': a['account_no_masked']})),
              subtitle: Text([
                (a['business_name'] as String).isNotEmpty ? a['business_name'] : a['holder_name'],
                a['account_type'] == 'CURRENT' ? tr('Current (Merchant)') : tr('Savings'),
                a['branch'],
                if (a['already_linked'] == true) tr('Already linked'),
              ].join(' • ')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() => _account = a),
            ),
          ),
      ],
    ]);
  }

  Widget _cardStep() => Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text(tr('Set UPI PIN'), style: Theme.of(context).textTheme.titleLarge),
          Text(tr('{bank} A/c {account}', {'bank': _bank!.name, 'account': _account!['account_no_masked']})),
          const SizedBox(height: 16),
          Text(tr('Enter your debit card details. You can see them in your bank app under "Debit card".')),
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
          const Divider(height: 24),
          TextFormField(
            controller: _pin,
            obscureText: true,
            maxLength: 4,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: tr('New 4-digit UPI PIN')),
            validator: (v) => RegExp(r'^\d{4}$').hasMatch(v ?? '') ? null : tr('Enter 4 digits'),
          ),
          TextFormField(
            controller: _pin2,
            obscureText: true,
            maxLength: 4,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: tr('Confirm UPI PIN')),
            validator: (v) => v != _pin.text ? tr('PINs do not match') : null,
          ),
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            onPressed: _busy ? null : _link,
            child: Text(_busy ? tr('Linking…') : tr('Set UPI PIN & link')),
          ),
          TextButton(onPressed: () => setState(() => _account = null), child: Text(tr('Back'))),
        ]),
      );
}
