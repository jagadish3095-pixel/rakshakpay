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
          rows.add(_LeafRow(depth + 1, Icons.atm, null,
              e['location'] != null
                  ? tr('ATM cash {amount} at {place}', {'amount': rupees(e['amount']), 'place': e['location']['label']})
                  : tr('ATM cash {amount}', {'amount': rupees(e['amount'])}),
              '${tr('Lost as cash')} • ${formatDateTime(e['date'])} • UTR ${e['utr']}'));
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
      (tr('held {amount}'), n['held'], strong(context, Colors.orange)),
      (tr('spent at shop {amount}'), n['spent_merchant'], strong(context, Colors.green)),
      (tr('ATM cash {amount}'), n['cashed_out'], Theme.of(context).colorScheme.onSurface),
      (tr('crypto frozen {amount}'), n['crypto_frozen'], strong(context, Colors.purple)),
      (tr('crypto escaped {amount}'), n['crypto_escaped'], strong(context, Colors.red)),
      (tr('court lien {amount}'), n['recovery_approved'], strong(context, Colors.brown)),
      (tr('returned {amount}'), n['released'] + n['crypto_released'], strong(context, Colors.green)),
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
                Text('↳ ${tr('{amount} via {channel}', {'amount': rupees(via!['amount']), 'channel': via!['channel']})}'
                    ' • ${formatDateTime(via!['date'])}'
                    '${via!['location'] != null ? ' • ${tr('from {place}', {'place': via!['location']['label']})}' : ''}',
                    style: TextStyle(fontSize: 11, color: muted(context))),
              Row(children: [
                Icon(n['role'] == 'MERCHANT' ? Icons.storefront : n['role'] == 'EXCHANGE' ? Icons.currency_bitcoin : Icons.person,
                    color: color),
                const SizedBox(width: 6),
                Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
                Text(roleLabel(n['role']), style: TextStyle(color: color, fontSize: 12)),
              ]),
              Text('${n['bank']} ${tr('A/c')} ${n['account_no']} • ${n['status']}', style: const TextStyle(fontSize: 12)),
              if (chips.isNotEmpty)
                Wrap(spacing: 6, runSpacing: 4, children: [
                  for (final (label, amount, c) in chips)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(label.replaceAll('{amount}', rupees(amount, decimals: false)),
                          style: TextStyle(color: c, fontSize: 11)),
                      side: BorderSide(color: c),
                      backgroundColor: Theme.of(context).colorScheme.surface,
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
  final Color? color; // null: the normal text colour
  final String title, subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 22.0),
      child: Card(
        color: panelBg(context),
        child: ListTile(
          dense: true,
          leading: Icon(icon, color: color ?? Theme.of(context).colorScheme.onSurface),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle),
        ),
      ),
    );
  }
}
