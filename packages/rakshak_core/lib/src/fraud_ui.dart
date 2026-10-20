import 'package:flutter/material.dart';

import 'api.dart';
import 'location.dart';
import 'money.dart';
import 'widgets.dart';

/// Report a payment as fraud (like calling 1930). Used by the bank apps and RakshakPay.
class ReportFraudScreen extends StatefulWidget {
  const ReportFraudScreen({
    super.key,
    required this.api,
    required this.location,
    required this.postPath, // '/api/complaints' or '/api/upi/complaints'
    required this.utr,
    required this.amount,
    required this.paidTo,
    required this.date,
  });

  final RakshakApi api;
  final LocationService location;
  final String postPath, utr, paidTo, date;
  final int amount;

  @override
  State<ReportFraudScreen> createState() => _ReportFraudScreenState();
}

class _ReportFraudScreenState extends State<ReportFraudScreen> {
  List<String> _categories = [];
  String? _category;
  final _description = TextEditingController();
  bool _confirm = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    widget.api.get('/api/complaint-categories').then((c) {
      if (mounted) setState(() => _categories = (c as List).cast<String>());
    }, onError: (e) {
      if (mounted) showError(context, e);
    });
  }

  Future<void> _submit() async {
    if (_category == null) return showError(context, 'Choose what happened');
    if (!_confirm) return showError(context, 'Please confirm the declaration');
    setState(() => _busy = true);
    try {
      final loc = await widget.location.current();
      final res = await widget.api.post(widget.postPath, {
        'utr': widget.utr,
        'category': _category,
        'description': _description.text,
        'location': loc.toJson(),
      });
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => _ComplaintFiledScreen(res)));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report fraud (1930)')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          color: Colors.red.shade50,
          child: ListTile(
            leading: const Icon(Icons.report, color: Colors.red),
            title: Text('${rupees(widget.amount)} paid to ${widget.paidTo}'),
            subtitle: Text('UTR ${widget.utr}\n${formatDateTime(widget.date)}'),
            isThreeLine: true,
          ),
        ),
        const SizedBox(height: 8),
        const Text('Report as soon as possible: money that is still in the fraudster\'s accounts can be '
            'held only before it is withdrawn.'),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _category,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'What happened?'),
          items: [for (final c in _categories) DropdownMenuItem(value: c, child: Text(c))],
          onChanged: (v) => setState(() => _category = v),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _description,
          maxLines: 4,
          maxLength: 1000,
          decoration: const InputDecoration(
            labelText: 'Describe what happened (optional)',
            hintText: 'e.g. A caller said my KYC expired and asked me to pay to unblock my account',
          ),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _confirm,
          onChanged: (v) => setState(() => _confirm = v!),
          title: const Text('I declare this information is true. A false complaint is punishable '
              '(BNS sections 217 and 248).'),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700, padding: const EdgeInsets.all(16)),
          onPressed: _busy ? null : _submit,
          icon: const Icon(Icons.send),
          label: Text(_busy ? 'Tracing your money…' : 'Submit complaint'),
        ),
      ]),
    );
  }
}

class _ComplaintFiledScreen extends StatelessWidget {
  const _ComplaintFiledScreen(this.c);
  final Map<String, dynamic> c;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complaint registered'), automaticallyImplyLeading: false),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Icon(Icons.verified_user, size: 72, color: Colors.green),
        const SizedBox(height: 8),
        const Text('Acknowledgement number', textAlign: TextAlign.center),
        SelectableText(c['ack_no'], textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ComplaintCard(c),
        const SizedBox(height: 12),
        const Text('Your money was traced within seconds. Amounts on hold are returned to you after the court\'s '
            'order. Keep this acknowledgement number.', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
      ]),
    );
  }
}

/// Summary of one complaint: amount, accounts traced, money on hold, money recovered.
class ComplaintCard extends StatelessWidget {
  const ComplaintCard(this.c, {super.key});
  final Map<String, dynamic> c;

  @override
  Widget build(BuildContext context) {
    final status = c['status'] as String;
    Widget row(String k, String v, {Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Expanded(child: Text(k)),
            Text(v, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ]),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(c['ack_no'], style: const TextStyle(fontWeight: FontWeight.bold))),
            Chip(
              label: Text(switch (status) { 'TRACED' => 'Traced', 'REFUNDED' => 'Refunded', _ => status }),
              backgroundColor: status == 'REFUNDED' ? Colors.green.shade100 : Colors.blue.shade100,
            ),
          ]),
          Text('${c['category']} • ${formatDateTime(c['date'])}', style: const TextStyle(fontSize: 12)),
          const Divider(),
          row('Amount reported', rupees(c['amount'])),
          row('Accounts traced', '${c['accounts_traced']} (${c['mules']} suspected mules)'),
          row('On hold for you', rupees(c['held']), color: Colors.orange.shade800),
          row('Returned to you', rupees(c['recovered']), color: Colors.green.shade700),
        ]),
      ),
    );
  }
}

/// All complaints filed by this user.
class ComplaintsScreen extends StatelessWidget {
  const ComplaintsScreen({super.key, required this.api, required this.path});
  final RakshakApi api;
  final String path; // '/api/complaints' or '/api/upi/complaints'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My fraud complaints')),
      body: FutureBuilder(
        future: api.get(path),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text(snap.error.toString()));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = (snap.data as List).cast<Map<String, dynamic>>();
          if (list.isEmpty) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No complaints. To report a payment, open it in your history and tap "Report fraud".',
                  textAlign: TextAlign.center),
            ));
          }
          return ListView(padding: const EdgeInsets.all(12), children: [for (final c in list) ComplaintCard(c)]);
        },
      ),
    );
  }
}

/// Messages about the user's accounts (holds, mule list, court orders, refunds).
class NoticesScreen extends StatelessWidget {
  const NoticesScreen({super.key, required this.api, required this.path});
  final RakshakApi api;
  final String path; // '/api/notices' or '/api/upi/notices'

  static IconData _icon(String kind) => switch (kind) {
        'MULE' => Icons.gpp_bad,
        'RECOVERY' => Icons.gavel,
        'REFUND' => Icons.savings,
        'COMPLAINT' => Icons.verified_user,
        _ => Icons.info,
      };

  static Color _color(String kind) => switch (kind) {
        'MULE' || 'RECOVERY' => Colors.red,
        'REFUND' || 'COMPLAINT' => Colors.green,
        _ => Colors.blue,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notices')),
      body: FutureBuilder(
        future: api.get(path),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text(snap.error.toString()));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = (snap.data as List).cast<Map<String, dynamic>>();
          if (list.isEmpty) return const Center(child: Text('No notices'));
          return ListView(padding: const EdgeInsets.all(12), children: [
            for (final n in list)
              Card(
                child: ListTile(
                  leading: Icon(_icon(n['kind']), color: _color(n['kind'])),
                  title: Text(n['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${n['body']}\n${formatDateTime(n['date'])}'),
                  isThreeLine: true,
                ),
              ),
          ]);
        },
      ),
    );
  }
}

/// Red warning shown on the payee card when the account is on the mule list.
class MuleWarningCard extends StatelessWidget {
  const MuleWarningCard(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade700,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.warning_amber, color: Colors.white, size: 32),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
        ]),
      ),
    );
  }
}

/// Asks the payer to confirm before paying an account on the mule list.
/// Returns true only if they choose "Pay anyway (repayment)".
Future<bool> confirmPayMule(BuildContext context, String message) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.warning_amber, color: Colors.red, size: 48),
      title: const Text('This account is on the mule list'),
      content: Text(message),
      actions: [
        FilledButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel payment')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Pay anyway (repayment)', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
  return ok == true;
}
