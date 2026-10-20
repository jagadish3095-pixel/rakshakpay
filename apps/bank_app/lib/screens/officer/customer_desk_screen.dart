import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../../services.dart';
import 'officer_home_screen.dart' show VerificationCaseCard;
import 'verification_screen.dart';

/// Everything the branch officer needs about one customer.
class CustomerDeskScreen extends StatefulWidget {
  const CustomerDeskScreen({super.key, required this.cif});
  final String cif;

  @override
  State<CustomerDeskScreen> createState() => _CustomerDeskScreenState();
}

class _CustomerDeskScreenState extends State<CustomerDeskScreen> {
  Map<String, dynamic>? _c;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await officerApi.get('/api/officer/customers/${widget.cif}');
      if (mounted) setState(() => _c = c);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    final accounts = (c['accounts'] as List).cast<Map<String, dynamic>>();
    final cases = (c['cases'] as List).cast<Map<String, dynamic>>();
    final pending = cases.any((x) => x['status'] == 'PENDING_POLICE');
    final toVerify = accounts.where((a) => a['status'] == 'SUSPECTED_MULE').toList();

    Widget section(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
          child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        );

    return Scaffold(
      appBar: AppBar(title: Text(c['name'])),
      floatingActionButton: toVerify.isNotEmpty && !pending
          ? FloatingActionButton.extended(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.fact_check),
              label: const Text('Start mule verification'),
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => VerificationScreen(customer: c, account: toVerify.first)));
                _load();
              },
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 96), children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CIF ${c['cif']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('DOB ${formatDate(c['dob'])} • ${c['gender']}'),
                Text('Mobile +91 ${c['mobile']}'),
                Text('PAN ${c['pan']} • Aadhaar ${c['aadhaar_masked']}'),
                Text(c['address']),
              ]),
            ),
          ),
          if (pending)
            Card(
              color: Colors.blueGrey.shade50,
              child: const ListTile(
                leading: Icon(Icons.hourglass_top),
                title: Text('Verification is with the police'),
                subtitle: Text('The account stays restricted until the police decide.'),
              ),
            ),
          section('Accounts'),
          for (final a in accounts)
            Card(
              child: ListTile(
                title: Text('A/c ${a['account_no']} • ${a['account_type'] == 'CURRENT' ? 'Current' : 'Savings'}'),
                subtitle: Text('Balance ${rupees(a['balance'])} • on hold ${rupees(a['lien_amount'])}\n'
                    'Available ${rupees(a['available_balance'])}'),
                isThreeLine: true,
                trailing: StatusBadge(a['status']),
              ),
            ),
          if ((c['other_banks'] as List).isNotEmpty) ...[
            section('Same PAN in other banks'),
            for (final o in c['other_banks'])
              Card(child: ListTile(title: Text('${o['bank']} • ${o['account_no_masked']}'), trailing: StatusBadge(o['status']))),
          ],
          section('Fraud involvement'),
          if ((c['involvement'] as List).isEmpty) const Text('  Not found in any money trail'),
          for (final i in c['involvement'])
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${i['complaint']} • ${i['category']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Victim money received ${rupees(i['received'])}, forwarded ${rupees(i['forwarded'])}'),
                  if (i['held'] > 0) Text('Held for victim: ${rupees(i['held'])}'),
                  if (i['spent_merchant'] > 0) Text('Spent at merchants: ${rupees(i['spent_merchant'])}'),
                  if (i['cashed_out'] > 0) Text('Withdrawn as cash: ${rupees(i['cashed_out'])}'),
                  if (i['to_crypto'] > 0) Text('Sent to crypto exchange: ${rupees(i['to_crypto'])}'),
                  for (final o in i['court_orders'])
                    Text('Court recovery ${rupees(o['amount'])}: ${o['status'] == 'APPROVED' ? 'approved' : 'pending'}'),
                ]),
              ),
            ),
          if (cases.isNotEmpty) ...[
            section('Verifications'),
            for (final x in cases) VerificationCaseCard(x),
          ],
          section('Notices sent to the customer'),
          for (final n in c['notices'])
            Card(child: ListTile(title: Text(n['title']), subtitle: Text('${n['body']}\n${formatDateTime(n['date'])}'))),
        ]),
      ),
    );
  }
}
