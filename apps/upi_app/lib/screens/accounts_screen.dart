import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';
import 'link_bank_screen.dart';

/// Linked bank accounts and balance check (needs UPI PIN, like real UPI).
class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key, required this.profile, this.askBalance = false});
  final UpiProfile profile;
  final bool askBalance;

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  @override
  void initState() {
    super.initState();
    // "Check balance" with a single account goes straight to the PIN.
    if (widget.askBalance && widget.profile.vpas.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkBalance(widget.profile.vpas.first));
    }
  }

  Future<void> _checkBalance(UpiVpa vpa) async {
    final bank = BankBrand.byCode(vpa.bankCode);
    final pin = await askPin(context, title: 'Enter UPI PIN', subtitle: '${bank.name} A/c ${vpa.accountNoMasked}');
    if (pin == null || !mounted) return;
    try {
      final res = await api.post('/api/upi/balance', {'vpa': vpa.address, 'upi_pin': pin});
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: BankLogo(bank, size: 48),
          title: Text(bank.name),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('A/c ${vpa.accountNoMasked}'),
            const SizedBox(height: 12),
            const Text('Available balance'),
            Text(rupees(res['available_balance']),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            if ((res['lien_amount'] as int) > 0)
              Text('On hold: ${rupees(res['lien_amount'])}', style: const TextStyle(color: Colors.orange)),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bank accounts')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final v in widget.profile.vpas)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: BankLogo(BankBrand.byCode(v.bankCode), size: 44),
                    title: Text(BankBrand.byCode(v.bankCode).name),
                    subtitle: Text('A/c ${v.accountNoMasked}${v.isMerchant ? ' • Merchant' : ''}\n${v.address}'),
                    isThreeLine: true,
                    trailing: StatusBadge(v.status),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonal(onPressed: () => _checkBalance(v), child: const Text('Check balance')),
                  ),
                ]),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const LinkBankScreen())),
            icon: const Icon(Icons.add),
            label: const Text('Link another bank account'),
          ),
        ],
      ),
    );
  }
}
