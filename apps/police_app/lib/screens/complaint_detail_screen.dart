import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';
import '../widgets/trail_map.dart';
import '../widgets/trail_tree.dart';
import 'court_orders_screen.dart';

/// One complaint: summary, map, money trail and court orders, with the refund action.
class ComplaintDetailScreen extends StatefulWidget {
  const ComplaintDetailScreen({super.key, required this.complaintId});
  final int complaintId;

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> with LiveRefresh {
  Map<String, dynamic>? _d;

  @override
  void initState() {
    super.initState();
    reload();
    startLive();
  }

  @override
  Future<void> reload() async {
    try {
      final d = await api.get('/api/police/complaints/${widget.complaintId}');
      if (mounted) setState(() => _d = d);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _release() async {
    final t = _d!['totals'] as Map<String, dynamic>;
    final accounts = t['release_now_accounts'] as int, crypto = t['release_now_crypto'] as int;
    final waitRecovery = t['waiting_court_recovery'] as int, waitCrypto = t['waiting_court_crypto'] as int;
    Widget line(String label, int amount, {Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Expanded(child: Text(label)),
            Text(rupees(amount), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ]),
        );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Release money to the victim?'),
        content: SizedBox(
          width: 460,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Under the magistrate\'s refund order, this pays:'),
            const SizedBox(height: 8),
            line('Held money + approved recovery liens (as far as balances allow)', accounts),
            line('Frozen crypto with an approved seizure order', crypto),
            const Divider(),
            line('Total paid now', accounts + crypto, color: Colors.green.shade700),
            if (waitRecovery + waitCrypto > 0) ...[
              const SizedBox(height: 12),
              const Text('Not paid yet: waiting for court approval (Court orders tab)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              if (waitRecovery > 0) line('Recovery liens (spent / cash / escaped crypto)', waitRecovery, color: Colors.brown),
              if (waitCrypto > 0) line('Crypto seizure at the exchange', waitCrypto, color: Colors.brown),
            ],
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: accounts + crypto > 0 ? () => Navigator.pop(ctx, true) : null,
            child: const Text('Release'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final res = await api.post('/api/police/complaints/${widget.complaintId}/release');
      if (!mounted) return;
      showInfo(context, res['released'] > 0
          ? '${rupees(res['released'])} returned to the victim'
          : 'Nothing new to release (balances are empty or already released)');
      reload();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(d?['ack_no'] ?? 'Complaint'),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: kAmber,
            tabs: [
              Tab(icon: Icon(Icons.summarize), text: 'Summary'),
              Tab(icon: Icon(Icons.map), text: 'Map'),
              Tab(icon: Icon(Icons.account_tree), text: 'Money trail'),
              Tab(icon: Icon(Icons.gavel), text: 'Court orders'),
            ],
          ),
        ),
        body: d == null
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                physics: const NeverScrollableScrollPhysics(), // so the map can be dragged
                children: [
                  _Summary(d, onRelease: _release),
                  TrailMap(d),
                  TrailTree(d),
                  CourtOrderList(orders: (d['court_orders'] as List).cast<Map<String, dynamic>>(), onChanged: reload),
                ],
              ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary(this.d, {required this.onRelease});
  final Map<String, dynamic> d;
  final VoidCallback onRelease;

  @override
  Widget build(BuildContext context) {
    final t = d['totals'] as Map<String, dynamic>;
    final victim = (d['nodes'] as List).cast<Map<String, dynamic>>().firstWhere((n) => n['role'] == 'VICTIM');
    String r(String k) => rupees(t[k] as int, decimals: false);
    // Only what can be paid right now (pending court orders are excluded).
    final releasable = (t['release_now_accounts'] as int) + (t['release_now_crypto'] as int);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text('${victim['holder']} • ${victim['bank']} A/c ${victim['account_no']}'),
          subtitle: Text('${d['category']} • reported ${formatDateTime(d['date'])} via ${d['channel']}\n'
              'Payment UTR ${d['utr']}${(d['description'] as String).isNotEmpty ? '\n"${d['description']}"' : ''}'),
          isThreeLine: true,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        StatTile('Amount lost', rupees(d['amount'], decimals: false), color: Colors.red.shade700, icon: Icons.report),
        StatTile('Accounts traced', '${d['accounts_traced']} (${d['mules']} mules)', icon: Icons.account_tree),
        StatTile('Held (lien)', r('held'), color: Colors.orange.shade800, icon: Icons.lock),
        StatTile('Crypto frozen', r('crypto_frozen'), color: Colors.purple, icon: Icons.ac_unit),
        StatTile('Spent at merchants', r('spent_merchant'), color: Colors.green.shade800, icon: Icons.storefront),
        StatTile('ATM cash', r('cashed_out'), color: Colors.black87, icon: Icons.atm),
        StatTile('Crypto escaped', r('crypto_escaped'), color: Colors.red.shade900, icon: Icons.flight_takeoff),
        StatTile('Court: pending', r('court_pending'), color: Colors.brown, icon: Icons.gavel),
        StatTile('Court: approved', r('court_approved'), color: Colors.brown, icon: Icons.gavel),
        StatTile('Returned to victim', r('recovered'), color: Colors.green.shade700, icon: Icons.savings),
      ]),
      const SizedBox(height: 16),
      FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700, padding: const EdgeInsets.all(16)),
        onPressed: onRelease,
        icon: const Icon(Icons.currency_rupee),
        label: Text(releasable > 0
            ? 'Release to victim (court refund order) – ${rupees(releasable, decimals: false)} now'
            : 'Release to victim – nothing to release now'),
      ),
      const SizedBox(height: 8),
      const Text('Tip: the Map tab has a Play button that replays the money moving between accounts.',
          style: TextStyle(color: Colors.black54)),
    ]);
  }
}
