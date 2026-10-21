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

  static (String, MaterialColor) _look(String? decision) => switch (decision) {
        'INNOCENT' => (tr('Innocent'), Colors.green),
        'TRICKED' => (tr('Tricked'), Colors.orange),
        'INVOLVED' => (tr('Involved'), Colors.red),
        _ => (tr('Waiting'), Colors.blueGrey),
      };

  /// Display name of a re-KYC check code sent by the server.
  static String _kyc(Object? code) => switch (code) {
        'pan_original' => tr('Original PAN card'),
        'aadhaar_original' => tr('Original Aadhaar card'),
        'live_photo' => tr('Live photo'),
        'mobile_otp' => tr('Mobile OTP'),
        _ => '$code',
      };

  /// The branch's reason category (one of a fixed English list on the server), translated for display.
  static String _reason(Object? category) {
    final english = '$category';
    return tr(english);
  }

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
              Text('${tr('A/c')} ${c['account_no']} • PAN ${c['pan']} • +91 ${c['mobile']}'),
              Text(tr('Verified at {branch} by {officer} on {date}',
                  {'branch': c['branch'], 'officer': c['officer'], 'date': formatDateTime(c['date'])})),
              Text(tr('Re-KYC done: {checks}', {'checks': (c['kyc_checks'] as List).map(_kyc).join(', ')})),
              const Divider(),
              Text(tr('Customer says: {reason}', {'reason': _reason(c['reason_category'])}),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('"${c['statement']}"'),
              const SizedBox(height: 8),
              Text(tr('Bank officer recommends: {decision}', {'decision': _look(c['recommendation']).$1}),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              if ((c['officer_notes'] as String).isNotEmpty) Text(tr('Notes: {notes}', {'notes': c['officer_notes']})),
              if (c['undertaking_signed'] == true) Text(tr('✔ Undertaking signed')),
              if (c['awareness_done'] == true) Text(tr('✔ Awareness session attended')),
              const Divider(),
              Text(tr('Fraud involvement'), style: const TextStyle(fontWeight: FontWeight.bold)),
              for (final i in c['involvement'])
                Text('${i['complaint']}: ${tr('received {amount}', {'amount': rupees(i['received'])})}, '
                    '${tr('forwarded {amount}', {'amount': rupees(i['forwarded'])})}'
                    '${i['held'] > 0 ? ', ${tr('held {amount}', {'amount': rupees(i['held'])})}' : ''}'
                    '${i['spent_merchant'] > 0 ? ', ${tr('spent {amount}', {'amount': rupees(i['spent_merchant'])})}' : ''}'
                    '${i['cashed_out'] > 0 ? ', ${tr('ATM cash {amount}', {'amount': rupees(i['cashed_out'])})}' : ''}'
                    '${i['to_crypto'] > 0 ? ', ${tr('to crypto {amount}', {'amount': rupees(i['to_crypto'])})}' : ''}'),
              if (c['status'] == 'PENDING_POLICE') ...[
                const SizedBox(height: 12),
                TextField(controller: remarks, maxLines: 2, decoration: InputDecoration(labelText: tr('Police remarks'))),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(tr('Decided {decision} by {name} on {date}', {
                        'decision': _look(c['decision']).$1,
                        'name': c['decided_by'],
                        'date': formatDateTime(c['decided_at']),
                      }) +
                      ((c['police_remarks'] as String).isNotEmpty ? '\n"${c['police_remarks']}"' : '')),
                ),
            ]),
          ),
        ),
        actions: c['status'] != 'PENDING_POLICE'
            ? [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Close')))]
            : [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Later'))),
                OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, 'INVOLVED'),
                  style: OutlinedButton.styleFrom(foregroundColor: strong(ctx, Colors.red)),
                  child: Text(tr('Involved: confirm mule')),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, 'TRICKED'),
                  style: OutlinedButton.styleFrom(foregroundColor: strong(ctx, Colors.orange)),
                  child: Text(tr('Tricked: restore with conditions')),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, 'INNOCENT'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
                  child: Text(tr('Innocent: delist')),
                ),
              ],
      ),
    );
    if (decision == null) return;
    try {
      await api.post('/api/police/verifications/${c['id']}/decide', {'decision': decision, 'remarks': remarks.text});
      if (mounted) {
        showInfo(context, tr('{name}: {decision}. The customer and bank have been notified.',
            {'name': c['customer'], 'decision': _look(decision).$1}));
      }
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
      return Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(tr('No branch verifications yet. Banks send them here after a flagged customer visits the branch.'),
            textAlign: TextAlign.center),
      ));
    }
    return ListView(padding: const EdgeInsets.all(12), children: [
      for (final c in list)
        Card(
          child: ListTile(
            leading: Icon(Icons.fact_check, color: strong(context, _look(c['decision']).$2)),
            title: Text('${c['customer']} • ${c['bank']} ${tr('A/c')} ${c['account_no']}'),
            subtitle: Text('${_reason(c['reason_category'])}\n'
                '${tr('Bank recommends {decision}', {'decision': _look(c['recommendation']).$1})} • ${formatDateTime(c['date'])}'),
            isThreeLine: true,
            trailing: Chip(
              label: Text(_look(c['decision']).$1,
                  style: TextStyle(color: strong(context, _look(c['decision']).$2))),
              side: BorderSide(color: _look(c['decision']).$2),
            ),
            onTap: () => _open(c),
          ),
        ),
    ]);
  }
}
