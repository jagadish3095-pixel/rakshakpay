import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../models.dart';
import '../services.dart';
import 'home_screen.dart' show PaymentTile;

/// All UPI payments, newest first. Refreshes by itself when money moves.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<UpiPayment>? _items;
  String _filter = 'ALL';
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
      appBar: AppBar(title: const Text('Payment history')),
      body: _items == null
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  for (final (key, label) in [('ALL', 'All'), ('SENT', 'Sent'), ('RECEIVED', 'Received')])
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
                      if (items.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('No payments')),
                      for (final p in items)
                        InkWell(
                          onTap: () => showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(p.sent ? 'Paid ${rupees(p.amount)}' : 'Received ${rupees(p.amount)}'),
                              content: Text([
                                '${p.sent ? 'To' : 'From'}: ${p.otherName} (${p.otherVpa})',
                                '${p.sent ? 'From' : 'To'}: ${p.myVpa}',
                                'UPI Ref (UTR): ${p.utr}',
                                'Date: ${formatDateTime(p.date)}',
                                if (p.remark.isNotEmpty) 'Note: ${p.remark}',
                                if (p.locationLabel.isNotEmpty) 'Location: ${p.locationLabel}',
                                'Status: ${p.status}',
                              ].join('\n')),
                              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
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
