import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import 'security_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.customer});
  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final acc = customer.accounts.first;
    Widget row(String label, String value) => ListTile(dense: true, title: Text(label), subtitle: Text(value));

    return Scaffold(
      appBar: AppBar(title: Text(tr('Profile & KYC'))),
      body: ListView(children: [
        const SizedBox(height: 16),
        CircleAvatar(radius: 36, child: Text(customer.fullName[0], style: const TextStyle(fontSize: 32))),
        const SizedBox(height: 8),
        Text(customer.fullName, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
        Center(
          child: TextButton.icon(
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => SecurityScreen(customer: customer))),
            icon: const Icon(Icons.lock_reset),
            label: Text(tr('Change password / MPIN / ATM PIN')),
          ),
        ),
        const Divider(height: 32),
        row(tr('Customer ID'), customer.cif),
        row(tr('Date of birth'), formatDate(customer.dob)),
        row(tr('Gender'), switch (customer.gender) {
          'Female' => tr('Female'),
          'Male' => tr('Male'),
          'Other' => tr('Other'),
          final g => g,
        }),
        row(tr('Mobile'), '+91 ${customer.mobile}'),
        if (customer.email.isNotEmpty) row(tr('Email'), customer.email),
        row(tr('PAN'), customer.pan),
        row(tr('Aadhaar'), customer.aadhaarMasked),
        row(tr('Address'), '${customer.address}, ${customer.city}, ${customer.state} - ${customer.pincode}'),
        const Divider(),
        row(tr('Account number'), acc.accountNo),
        row(tr('Account type'), acc.isMerchant ? tr('Current (Merchant)') : tr('Savings')),
        if (acc.isMerchant) row(tr('Business name'), acc.businessName),
        row(tr('Home branch'), acc.branch.name),
        row(tr('IFSC'), acc.branch.ifsc),
        row(tr('Opened on'), formatDate(acc.openedOn)),
      ]),
    );
  }
}
