import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';

/// Branch verifications of mules sent by banks: the police decide
/// innocent (delist), tricked (restore with conditions) or involved (confirm).
class VerificationsScreen extends StatefulWidget {
  const VerificationsScreen({super.key});

  @override
  State<VerificationsScreen> createState() => _VerificationsScreenState();
}

class _VerificationsScreenState extends State<VerificationsScreen> with LiveRefresh {
  List<Map<String, dynamic>>? _list;

  @override
  void initState() {
    super.initState();
    reload();
    startLive();
  }

  @override
  Future<void> reload() async {
    try {
      final list = (await api.get('/api/police/verifications') as List).cast<Map<String, dynamic>>();
      if (mounted) setState(() => _list = list);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  static (String, Color) _look(String? decision) => switch (decision) {
        'INNOCENT' => ('Innocent', Colors.green),
        'TRICKED' => ('Tricked', Colors.orange),
        'INVOLVED' => ('Involved', Colors.red),
        _ => ('Waiting', Colors.blueGrey),
      };

  Future<void> _open(Map<String, dynamic> c) async {
    final remarks = TextEditingController();
    final decision = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${c['customer']} • ${c['bank']}'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('A/c ${c['account_no']} • PAN ${c['pan']} • +91 ${c['mobile']}'),
              Text('Verified at ${c['branch']} by ${c['officer']} on ${formatDateTime(c['date'])}'),
              Text('Re-KYC done: ${(c['kyc_checks'] as List).join(', ')}'),
              const Divider(),
              Text('Customer says: ${c['reason_category']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('"${c['statement']}"'),
              const SizedBox(height: 8),
              Text('Bank officer recommends: ${c['recommendation']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              if ((c['officer_notes'] as String).isNotEmpty) Text('Notes: ${c['officer_notes']}'),
              if (c['undertaking_signed'] == true) const Text('✔ Undertaking signed'),
              if (c['awareness_done'] == true) const Text('✔ Awareness session attended'),
              const Divider(),
              const Text('Fraud involvement', style: TextStyle(fontWeight: FontWeight.bold)),
              for (final i in c['involvement'])
                Text('${i['complaint']}: received ${rupees(i['received'])}, forwarded ${rupees(i['forwarded'])}'
                    '${i['held'] > 0 ? ', held ${rupees(i['held'])}' : ''}'
                    '${i['spent_merchant'] > 0 ? ', spent ${rupees(i['spent_merchant'])}' : ''}'
                    '${i['cashed_out'] > 0 ? ', ATM cash ${rupees(i['cashed_out'])}' : ''}'
                    '${i['to_crypto'] > 0 ? ', to crypto ${rupees(i['to_crypto'])}' : ''}'),
              if (c['status'] == 'PENDING_POLICE') ...[
                const SizedBox(height: 12),
                TextField(controller: remarks, maxLines: 2, decoration: const InputDecoration(labelText: 'Police remarks')),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text('Decided ${c['decision']} by ${c['decided_by']} on ${formatDateTime(c['decided_at'])}'
                      '${(c['police_remarks'] as String).isNotEmpty ? '\n"${c['police_remarks']}"' : ''}'),
                ),
            ]),
          ),
        ),
        actions: c['status'] != 'PENDING_POLICE'
            ? [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))]
            : [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Later')),
                OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, 'INVOLVED'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Involved: confirm mule'),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, 'TRICKED'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.orange.shade800),
                  child: const Text('Tricked: restore with conditions'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, 'INNOCENT'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
                  child: const Text('Innocent: delist'),
                ),
              ],
      ),
    );
    if (decision == null) return;
    try {
      await api.post('/api/police/verifications/${c['id']}/decide', {'decision': decision, 'remarks': remarks.text});
      if (mounted) showInfo(context, '${c['customer']}: ${_look(decision).$1}. The customer and bank have been notified.');
      reload();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;
    if (list == null) return const Center(child: CircularProgressIndicator());
    if (list.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('No branch verifications yet. Banks send them here after a flagged customer visits the branch.',
            textAlign: TextAlign.center),
      ));
    }
    return ListView(padding: const EdgeInsets.all(12), children: [
      for (final c in list)
        Card(
          child: ListTile(
            leading: Icon(Icons.fact_check, color: _look(c['decision']).$2),
            title: Text('${c['customer']} • ${c['bank']} A/c ${c['account_no']}'),
            subtitle: Text('${c['reason_category']}\nBank recommends ${c['recommendation']} • ${formatDateTime(c['date'])}'),
            isThreeLine: true,
            trailing: Chip(
              label: Text(_look(c['decision']).$1, style: TextStyle(color: _look(c['decision']).$2)),
              side: BorderSide(color: _look(c['decision']).$2),
            ),
            onTap: () => _open(c),
          ),
        ),
    ]);
  }
}
