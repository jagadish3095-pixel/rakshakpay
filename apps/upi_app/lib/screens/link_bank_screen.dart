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
          title: const Text('Bank account linked'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Your UPI ID is'),
            const SizedBox(height: 6),
            SelectableText(res['vpa']['address'],
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Remember your UPI PIN. You need it for every payment.', textAlign: TextAlign.center),
          ]),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))],
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
      appBar: AppBar(title: const Text('Link bank account')),
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
        Text('Select your bank', style: Theme.of(context).textTheme.titleLarge),
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
        TextButton(onPressed: () => setState(() => _bank = null), child: const Text('Change')),
      ]),
      const SizedBox(height: 16),
      if (accounts.isEmpty)
        Card(
          color: Colors.orange.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('No ${_bank!.name} account is registered with your mobile number.\n\n'
                'Open an account in the ${_bank!.name} app using the same mobile number, then try again.'),
          ),
        )
      else ...[
        const Text('Accounts found with your mobile number:'),
        for (final a in accounts)
          Card(
            child: ListTile(
              enabled: a['already_linked'] != true,
              leading: Icon(a['account_type'] == 'CURRENT' ? Icons.storefront : Icons.savings),
              title: Text('A/c ${a['account_no_masked']}'),
              subtitle: Text([
                (a['business_name'] as String).isNotEmpty ? a['business_name'] : a['holder_name'],
                a['account_type'] == 'CURRENT' ? 'Current (Merchant)' : 'Savings',
                a['branch'],
                if (a['already_linked'] == true) 'Already linked',
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
          Text('Set UPI PIN', style: Theme.of(context).textTheme.titleLarge),
          Text('${_bank!.name} A/c ${_account!['account_no_masked']}'),
          const SizedBox(height: 16),
          const Text('Enter your debit card details. You can see them in your bank app under "Debit card".'),
          const SizedBox(height: 12),
          TextFormField(
            controller: _last6,
            maxLength: 6,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Last 6 digits of debit card'),
            validator: (v) => (v?.length ?? 0) == 6 ? null : 'Enter 6 digits',
          ),
          TextFormField(
            controller: _expiry,
            maxLength: 5,
            keyboardType: TextInputType.number,
            inputFormatters: [ExpiryFormatter()],
            decoration: const InputDecoration(labelText: 'Expiry (valid thru)', hintText: 'MM/YY'),
            validator: (v) => RegExp(r'^(0[1-9]|1[0-2])/\d{2}$').hasMatch(v ?? '') ? null : 'Format MM/YY',
          ),
          const Divider(height: 24),
          TextFormField(
            controller: _pin,
            obscureText: true,
            maxLength: 4,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'New 4-digit UPI PIN'),
            validator: (v) => RegExp(r'^\d{4}$').hasMatch(v ?? '') ? null : 'Enter 4 digits',
          ),
          TextFormField(
            controller: _pin2,
            obscureText: true,
            maxLength: 4,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Confirm UPI PIN'),
            validator: (v) => v != _pin.text ? 'PINs do not match' : null,
          ),
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            onPressed: _busy ? null : _link,
            child: Text(_busy ? 'Linking…' : 'Set UPI PIN & link'),
          ),
          TextButton(onPressed: () => setState(() => _account = null), child: const Text('Back')),
        ]),
      );
}
