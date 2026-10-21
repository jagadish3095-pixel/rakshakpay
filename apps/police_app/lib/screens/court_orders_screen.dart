import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';

/// All auto-drafted court applications.
class CourtOrdersScreen extends StatefulWidget {
  const CourtOrdersScreen({super.key});

  @override
  State<CourtOrdersScreen> createState() => _CourtOrdersScreenState();
}

class _CourtOrdersScreenState extends State<CourtOrdersScreen> with LiveRefresh {
  List<Map<String, dynamic>>? _orders;

  @override
  void initState() {
    super.initState();
    reload();
    startLive();
  }

  @override
  Future<void> reload() async {
    try {
      final list = (await api.get('/api/police/court-orders') as List).cast<Map<String, dynamic>>();
      if (mounted) setState(() => _orders = list);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _orders == null
        ? const Center(child: CircularProgressIndicator())
        : CourtOrderList(orders: _orders!, onChanged: reload);
  }
}

class CourtOrderList extends StatelessWidget {
  const CourtOrderList({super.key, required this.orders, required this.onChanged});
  final List<Map<String, dynamic>> orders;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('No court applications. They are drafted automatically when victim money was spent, '
            'withdrawn as cash or sent out as crypto.', textAlign: TextAlign.center),
      ));
    }
    return ListView(padding: const EdgeInsets.all(12), children: [
      for (final o in orders)
        Card(
          child: ListTile(
            leading: Icon(Icons.gavel, color: o['status'] == 'APPROVED' ? Colors.green : Colors.brown),
            title: Text('${o['holder']} • ${rupees(o['amount'])} • '
                '${o['kind'] == 'CRYPTO_SEIZURE' ? 'Crypto seizure' : 'Recovery lien'}'),
            subtitle: Text('${o['complaint_ack']} • ${o['bank']} A/c ${o['account_no']}\n${o['reason']}'),
            isThreeLine: true,
            trailing: Chip(
              label: Text(o['status'] == 'APPROVED' ? 'Approved' : 'Pending'),
              backgroundColor: o['status'] == 'APPROVED' ? Colors.green.shade100 : Colors.amber.shade100,
            ),
            onTap: () => _open(context, o),
          ),
        ),
    ]);
  }

  Future<void> _open(BuildContext context, Map<String, dynamic> o) async {
    final approve = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Application: ${o['holder']}'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.grey.shade100,
                child: SelectableText(o['application_text'], style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ),
              if (o['status'] == 'APPROVED')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Approved ${formatDateTime(o['approved_at'])} (recorded by ${o['approved_by']})',
                      style: const TextStyle(color: Colors.green)),
                ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Close')),
          if (o['status'] == 'PENDING')
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.gavel),
              label: const Text('Approve (simulate court)'),
            ),
        ],
      ),
    );
    if (approve != true || !context.mounted) return;
    try {
      await api.post('/api/police/court-orders/${o['id']}/approve');
      if (context.mounted) {
        showInfo(context, o['kind'] == 'CRYPTO_SEIZURE'
            ? 'Seizure approved: up to ${rupees(o['amount'])} of ${o['holder']}\'s frozen crypto can now be released to the victim'
            : 'Recovery lien of ${rupees(o['amount'])} placed on ${o['holder']}\'s account');
      }
      onChanged();
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}
