import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../brand.dart';
import '../models.dart';
import '../services.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ExchangeEntry>? _items;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = [for (final e in await api.get('/api/crypto/history') as List) ExchangeEntry.fromJson(e)];
      if (mounted) setState(() => _items = list);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('History'))),
      body: _items == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.all(12), children: [
                if (_items!.isEmpty) Padding(padding: const EdgeInsets.all(24), child: Text(tr('Nothing yet'))),
                for (final e in _items!)
                  Card(
                    child: ListTile(
                      leading: e.asset == 'INR'
                          ? const CircleAvatar(backgroundColor: kGold, child: Text('₹', style: TextStyle(color: kBg)))
                          : CoinIcon(e.asset),
                      title: Text(e.title),
                      subtitle: Text([
                        if (e.quantity > 0) '${formatQty(e.quantity)} ${e.asset}',
                        if (e.price != null) '@ ${rupees(e.price!)}',
                        if (e.address.isNotEmpty) tr('to {address}', {'address': e.address}),
                        if (e.utr.isNotEmpty) tr('UTR {utr}', {'utr': e.utr}),
                        formatDateTime(e.date),
                      ].join('\n')),
                      isThreeLine: true,
                      trailing: Text(rupees(e.inr), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
              ]),
            ),
    );
  }
}
