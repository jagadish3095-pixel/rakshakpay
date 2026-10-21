import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';
import 'complaint_detail_screen.dart';

class PoliceComplaintsScreen extends StatefulWidget {
  const PoliceComplaintsScreen({super.key});

  @override
  State<PoliceComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<PoliceComplaintsScreen> with LiveRefresh {
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
      final list = (await api.get('/api/police/complaints') as List).cast<Map<String, dynamic>>();
      if (mounted) setState(() => _list = list);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;
    if (list == null) return const Center(child: CircularProgressIndicator());
    if (list.isEmpty) return Center(child: Text(tr('No complaints yet')));
    return RefreshIndicator(
      onRefresh: reload,
      child: ListView(padding: const EdgeInsets.all(12), children: [for (final c in list) ComplaintTile(c)]),
    );
  }
}

class ComplaintTile extends StatelessWidget {
  const ComplaintTile(this.c, {super.key});
  final Map<String, dynamic> c;

  @override
  Widget build(BuildContext context) {
    final refunded = c['status'] == 'REFUNDED';
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: refunded ? chipBg(context, Colors.green) : chipBg(context, Colors.red),
          child: Icon(refunded ? Icons.check : Icons.report,
              color: refunded ? strong(context, Colors.green) : strong(context, Colors.red)),
        ),
        title: Text('${c['ack_no']} • ${rupees(c['amount'], decimals: false)}'),
        subtitle: Text('${c['category']} • ${formatDateTime(c['date'])}\n'
            '${tr('{count} accounts traced, {mules} mules', {'count': c['accounts_traced'], 'mules': c['mules']})}'
            ' • ${tr('held {amount}', {'amount': rupees(c['held'], decimals: false)})}'
            ' • ${tr('returned {amount}', {'amount': rupees(c['recovered'], decimals: false)})}'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => ComplaintDetailScreen(complaintId: c['id']))),
      ),
    );
  }
}
