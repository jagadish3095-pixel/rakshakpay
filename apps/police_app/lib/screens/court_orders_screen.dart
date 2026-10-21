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
      return Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(tr('No court applications. They are drafted automatically when victim money was spent, '
            'withdrawn as cash or sent out as crypto.'), textAlign: TextAlign.center),
      ));
    }
    return ListView(padding: const EdgeInsets.all(12), children: [
      for (final o in orders)
        Card(
          child: ListTile(
            leading: Icon(Icons.gavel,
                color: o['status'] == 'APPROVED' ? strong(context, Colors.green) : strong(context, Colors.brown)),
            title: Text('${o['holder']} • ${rupees(o['amount'])} • '
                '${o['kind'] == 'CRYPTO_SEIZURE' ? tr('Crypto seizure') : tr('Recovery lien')}'),
            subtitle: Text('${o['complaint_ack']} • ${o['bank']} ${tr('A/c')} ${o['account_no']}\n${o['reason']}'),
            isThreeLine: true,
            trailing: Chip(
              label: Text(o['status'] == 'APPROVED' ? tr('Approved') : tr('Pending')),
              backgroundColor: o['status'] == 'APPROVED' ? chipBg(context, Colors.green) : chipBg(context, Colors.amber),
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
        title: Text(tr('Application: {name}', {'name': o['holder']})),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: panelBg(ctx),
                child: SelectableText(o['application_text'], style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ),
              if (o['status'] == 'APPROVED')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                      tr('Approved {date} (recorded by {name})',
                          {'date': formatDateTime(o['approved_at']), 'name': o['approved_by']}),
                      style: TextStyle(color: strong(ctx, Colors.green))),
                ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Close'))),
          if (o['status'] == 'PENDING')
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.gavel),
              label: Text(tr('Approve (simulate court)')),
            ),
        ],
      ),
    );
    if (approve != true || !context.mounted) return;
    try {
      await api.post('/api/police/court-orders/${o['id']}/approve');
      if (context.mounted) {
        showInfo(context, o['kind'] == 'CRYPTO_SEIZURE'
            ? tr("Seizure approved: up to {amount} of {name}'s frozen crypto can now be released to the victim",
                {'amount': rupees(o['amount']), 'name': o['holder']})
            : tr("Recovery lien of {amount} placed on {name}'s account", {'amount': rupees(o['amount']), 'name': o['holder']}));
      }
      onChanged();
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}
