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
      appBar: AppBar(title: const Text('Profile & KYC')),
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
            label: const Text('Change password / MPIN / ATM PIN'),
          ),
        ),
        const Divider(height: 32),
        row('Customer ID', customer.cif),
        row('Date of birth', formatDate(customer.dob)),
        row('Gender', customer.gender),
        row('Mobile', '+91 ${customer.mobile}'),
        if (customer.email.isNotEmpty) row('Email', customer.email),
        row('PAN', customer.pan),
        row('Aadhaar', customer.aadhaarMasked),
        row('Address', '${customer.address}, ${customer.city}, ${customer.state} - ${customer.pincode}'),
        const Divider(),
        row('Account number', acc.accountNo),
        row('Account type', acc.typeLabel),
        if (acc.isMerchant) row('Business name', acc.businessName),
        row('Home branch', acc.branch.name),
        row('IFSC', acc.branch.ifsc),
        row('Opened on', formatDate(acc.openedOn)),
      ]),
    );
  }
}
