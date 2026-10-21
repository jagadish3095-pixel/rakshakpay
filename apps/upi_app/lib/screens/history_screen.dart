import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';
import 'home_screen.dart' show PaymentTile;

/// All UPI payments, newest first. Refreshes by itself when money moves.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.reportMode = false});

  /// Opened from "Report fraud": show only sent payments and explain what to tap.
  final bool reportMode;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<UpiPayment>? _items;
  late String _filter = widget.reportMode ? 'SENT' : 'ALL';
  StreamSubscription<String>? _liveSub;

  @override
  void initState() {
    super.initState();
    _load();
    _liveSub = live.changes.listen((_) => _load());
  }

  @override
  void dispose() {
    _liveSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = [for (final p in await api.get('/api/upi/history') as List) UpiPayment.fromJson(p)];
      if (mounted) setState(() => _items = list);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (_items ?? []).where((p) => switch (_filter) {
          'SENT' => p.sent,
          'RECEIVED' => !p.sent,
          _ => true,
        });
    return Scaffold(
      appBar: AppBar(title: Text(tr('Payment history'))),
      body: _items == null
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              if (widget.reportMode)
                Card(
                  color: softBg(context, Colors.red),
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: ListTile(
                    leading: const Icon(Icons.report, color: Colors.red),
                    title: Text(tr('Which payment was fraud?')),
                    subtitle: Text(tr('Tap the payment, then "Report fraud".')),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  for (final (key, label) in [('ALL', tr('All')), ('SENT', tr('Sent')), ('RECEIVED', tr('Received'))])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: _filter == key,
                        onSelected: (_) => setState(() => _filter = key),
                      ),
                    ),
                ]),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      if (items.isEmpty) Padding(padding: const EdgeInsets.all(24), child: Text(tr('No payments'))),
                      for (final p in items)
                        InkWell(
                          onTap: () => showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(p.sent
                                  ? tr('Paid {amount}', {'amount': rupees(p.amount)})
                                  : tr('Received {amount}', {'amount': rupees(p.amount)})),
                              content: Text([
                                '${p.sent ? tr('To') : tr('From')}: ${p.otherName} (${p.otherVpa})',
                                '${p.sent ? tr('From') : tr('To')}: ${p.myVpa}',
                                '${tr('UPI Ref (UTR)')}: ${p.utr}',
                                '${tr('Date')}: ${formatDateTime(p.date)}',
                                if (p.remark.isNotEmpty) '${tr('Note')}: ${p.remark}',
                                if (p.locationLabel.isNotEmpty) '${tr('Location')}: ${p.locationLabel}',
                                '${tr('Status')}: ${p.status == 'SUCCESS' ? tr('Success') : p.status}',
                              ].join('\n')),
                              actions: [
                                if (p.sent)
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      Navigator.push(context, MaterialPageRoute(
                                        builder: (_) => ReportFraudScreen(
                                          api: api, location: location, postPath: '/api/upi/complaints',
                                          utr: p.utr, amount: p.amount, paidTo: p.otherName, date: p.date),
                                      ));
                                    },
                                    icon: const Icon(Icons.report, color: Colors.red),
                                    label: Text(tr('Report fraud'), style: const TextStyle(color: Colors.red)),
                                  ),
                                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Close'))),
                              ],
                            ),
                          ),
                          child: PaymentTile(p),
                        ),
                    ],
                  ),
                ),
              ),
            ]),
    );
  }
}
