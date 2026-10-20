import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';
import 'trail_map.dart' show showNodeDetails;

/// The money trail as an indented tree: victim -> scammer -> mules -> ...
class TrailTree extends StatelessWidget {
  const TrailTree(this.detail, {super.key});
  final Map<String, dynamic> detail;

  @override
  Widget build(BuildContext context) {
    final nodes = {for (final n in (detail['nodes'] as List).cast<Map<String, dynamic>>()) n['account_no'] as String: n};
    final edges = (detail['edges'] as List).cast<Map<String, dynamic>>();
    final out = <String, List<Map<String, dynamic>>>{};
    for (final e in edges) {
      out.putIfAbsent(e['from_account'], () => []).add(e);
    }
    final victim = nodes.values.firstWhere((n) => n['role'] == 'VICTIM');
    final rows = <Widget>[];
    final seen = <String>{};

    void walk(String account, int depth, Map<String, dynamic>? via) {
      final n = nodes[account]!;
      rows.add(_NodeRow(n, depth, via));
      if (!seen.add(account)) return; // already expanded (money merged back)
      for (final e in out[account] ?? const []) {
        if (e['kind'] == 'ATM') {
          rows.add(_LeafRow(depth + 1, Icons.atm, Colors.black87,
              'ATM cash ${rupees(e['amount'])}${e['location'] != null ? ' at ${e['location']['label']}' : ''}',
              'Lost as cash • ${formatDateTime(e['date'])} • UTR ${e['utr']}'));
        } else if (e['to_account'] != null && nodes.containsKey(e['to_account'])) {
          walk(e['to_account'], depth + 1, e);
        }
      }
    }

    walk(victim['account_no'], 0, null);
    return ListView(padding: const EdgeInsets.all(12), children: rows);
  }
}

class _NodeRow extends StatelessWidget {
  const _NodeRow(this.n, this.depth, this.via);
  final Map<String, dynamic> n;
  final int depth;
  final Map<String, dynamic>? via;

  @override
  Widget build(BuildContext context) {
    final color = roleColor(n['role']);
    final chips = <(String, int, Color)>[
      ('held', n['held'], Colors.orange.shade800),
      ('spent at shop', n['spent_merchant'], Colors.green.shade800),
      ('ATM cash', n['cashed_out'], Colors.black87),
      ('crypto frozen', n['crypto_frozen'], Colors.purple),
      ('crypto escaped', n['crypto_escaped'], Colors.red.shade900),
      ('court lien', n['recovery_approved'], Colors.brown),
      ('returned', n['released'] + n['crypto_released'], Colors.green),
    ].where((c) => c.$2 > 0);
    final name = (n['business_name'] as String).isNotEmpty ? '${n['business_name']} (${n['holder']})' : n['holder'];
    return Padding(
      padding: EdgeInsets.only(left: depth * 22.0),
      child: Card(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), side: BorderSide(color: color, width: 1.5)),
        child: InkWell(
          onTap: () => showNodeDetails(context, n),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (via != null)
                Text('↳ ${rupees(via!['amount'])} via ${via!['channel']} • ${formatDateTime(via!['date'])}'
                    '${via!['location'] != null ? ' • from ${via!['location']['label']}' : ''}',
                    style: const TextStyle(fontSize: 11, color: Colors.black54)),
              Row(children: [
                Icon(n['role'] == 'MERCHANT' ? Icons.storefront : n['role'] == 'EXCHANGE' ? Icons.currency_bitcoin : Icons.person,
                    color: color),
                const SizedBox(width: 6),
                Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
                Text(roleLabel(n['role']), style: TextStyle(color: color, fontSize: 12)),
              ]),
              Text('${n['bank']} A/c ${n['account_no']} • ${n['status']}', style: const TextStyle(fontSize: 12)),
              if (chips.isNotEmpty)
                Wrap(spacing: 6, runSpacing: 4, children: [
                  for (final (label, amount, c) in chips)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text('$label ${rupees(amount, decimals: false)}', style: TextStyle(color: c, fontSize: 11)),
                      side: BorderSide(color: c),
                      backgroundColor: Colors.white,
                    ),
                ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _LeafRow extends StatelessWidget {
  const _LeafRow(this.depth, this.icon, this.color, this.title, this.subtitle);
  final int depth;
  final IconData icon;
  final Color color;
  final String title, subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 22.0),
      child: Card(
        color: Colors.grey.shade100,
        child: ListTile(
          dense: true,
          leading: Icon(icon, color: color),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle),
        ),
      ),
    );
  }
}
