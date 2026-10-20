import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';

/// Every account on the mule list (in a money trail, or linked to one by PAN).
class MulesScreen extends StatefulWidget {
  const MulesScreen({super.key});

  @override
  State<MulesScreen> createState() => _MulesScreenState();
}

class _MulesScreenState extends State<MulesScreen> with LiveRefresh {
  List<Map<String, dynamic>>? _list;
  String _search = '';

  @override
  void initState() {
    super.initState();
    reload();
    startLive();
  }

  @override
  Future<void> reload() async {
    try {
      final list = (await api.get('/api/police/mules') as List).cast<Map<String, dynamic>>();
      if (mounted) setState(() => _list = list);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;
    if (list == null) return const Center(child: CircularProgressIndicator());
    final q = _search.toLowerCase();
    final shown = list.where((m) => q.isEmpty ||
        '${m['holder']} ${m['pan']} ${m['account_no']} ${m['mobile']} ${m['bank']}'.toLowerCase().contains(q));
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search name, PAN, account, mobile'),
          onChanged: (v) => setState(() => _search = v),
        ),
      ),
      Expanded(
        child: ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: [
          if (shown.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('No mule accounts')),
          for (final m in shown)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.shade100,
                  child: Icon(m['linked_by_pan_only'] == true ? Icons.link : Icons.gpp_bad, color: Colors.red),
                ),
                title: Text('${m['holder']} • PAN ${m['pan']}'),
                subtitle: Text('${m['bank']} A/c ${m['account_no']} • ${m['mobile']}\n'
                    '${m['linked_by_pan_only'] == true ? 'Linked by PAN (not in a trail)' : 'In ${m['complaints']} complaint(s)'}'
                    ' • lien ${rupees(m['lien_amount'], decimals: false)}'),
                isThreeLine: true,
                trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const Text('Available', style: TextStyle(fontSize: 11)),
                  Text(rupees(m['available_balance'], decimals: false),
                      style: TextStyle(fontWeight: FontWeight.bold,
                          color: (m['available_balance'] as int) < 0 ? Colors.red : Colors.black87)),
                ]),
              ),
            ),
        ]),
      ),
    ]);
  }
}
