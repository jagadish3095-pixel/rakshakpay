import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';

/// Change login password, MPIN and ATM PIN.
class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key, required this.customer});
  final Customer customer;

  Account get _account => customer.accounts.first;

  @override
  Widget build(BuildContext context) {
    Future<void> open(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

    return Scaffold(
      appBar: AppBar(title: const Text('Security settings')),
      body: ListView(children: [
        ListTile(
          leading: const Icon(Icons.password),
          title: const Text('Change login password'),
          subtitle: const Text('Used to log in to this app'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => open(ChangeSecretScreen(
            title: 'Change login password',
            what: 'password',
            pinDigits: null,
            submit: (current, next) async {
              await api.post('/api/security/password', {'current': current, 'new': next});
              // Keep one-tap saved logins working (saved by Customer ID or mobile).
              await savedLogins.updatePassword(customer.cif, next);
              await savedLogins.updatePassword(customer.mobile, next);
            },
          )),
        ),
        ListTile(
          leading: const Icon(Icons.pin),
          title: const Text('Change MPIN'),
          subtitle: const Text('4-digit PIN for payments and opening the app'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => open(ChangeSecretScreen(
            title: 'Change MPIN',
            what: 'MPIN',
            submit: (current, next) =>
                api.post('/api/accounts/${_account.accountNo}/mpin', {'current': current, 'new': next}),
          )),
        ),
        ListTile(
          leading: const Icon(Icons.atm),
          title: const Text('Change ATM / debit card PIN'),
          subtitle: Text('Card ending ${_account.cardNo.substring(12)}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => open(ChangeSecretScreen(
            title: 'Change ATM PIN',
            what: 'ATM PIN',
            submit: (current, next) =>
                api.post('/api/accounts/${_account.accountNo}/card-pin', {'current': current, 'new': next}),
          )),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Your UPI PIN is set and changed in the RakshakPay app.', style: TextStyle(color: Colors.black54)),
        ),
      ]),
    );
  }
}
