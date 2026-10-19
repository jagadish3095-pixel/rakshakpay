import 'dart:async';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../passbook_pdf.dart';
import '../services.dart';
import 'home_screen.dart' show EntryTile;

/// Full passbook. Updates by itself when money comes in or goes out.
class PassbookScreen extends StatefulWidget {
  const PassbookScreen({super.key, required this.accountNo});
  final String accountNo;

  @override
  State<PassbookScreen> createState() => _PassbookScreenState();
}

class _PassbookScreenState extends State<PassbookScreen> {
  Map<String, dynamic>? _data;
  List<PassbookEntry> _entries = [];
  String _filter = 'ALL';
  StreamSubscription<String>? _liveSub;
  bool _flash = false;

  @override
  void initState() {
    super.initState();
    _load();
    _liveSub = live.changes.listen((no) async {
      if (no != widget.accountNo) return;
      await _load();
      // Briefly highlight the screen so the live update is visible in a demo.
      setState(() => _flash = true);
      Future.delayed(const Duration(milliseconds: 800), () => mounted ? setState(() => _flash = false) : null);
    });
  }

  @override
  void dispose() {
    _liveSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await api.get('/api/accounts/${widget.accountNo}/passbook');
      if (!mounted) return;
      setState(() {
        _data = data;
        _entries = [for (final e in data['entries']) PassbookEntry.fromJson(e)];
      });
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown = _entries.reversed.where((e) => switch (_filter) {
          'CR' => e.isCredit,
          'DR' => !e.isCredit,
          _ => true,
        });
    final account = _data == null ? null : Account.fromJson(_data!['account']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Passbook'),
        actions: [
          IconButton(
            tooltip: 'Download PDF',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _data == null
                ? null
                : () => Navigator.push(context, MaterialPageRoute(builder: (_) => _PdfScreen(_data!))),
          ),
        ],
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: _flash ? Colors.yellow.shade100 : Colors.transparent,
        child: account == null
            ? const Center(child: CircularProgressIndicator())
            : Column(children: [
                ListTile(
                  title: Text('A/c ${account.accountNo}'),
                  subtitle: Text('${account.holderName} • ${account.branch.ifsc}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Balance', style: TextStyle(fontSize: 12)),
                      Text(rupees(account.balance), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    for (final (key, label) in [('ALL', 'All'), ('CR', 'Credits'), ('DR', 'Debits')])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: _filter == key,
                          onSelected: (_) => setState(() => _filter = key),
                        ),
                      ),
                    const Spacer(),
                    const Icon(Icons.circle, size: 10, color: Colors.green),
                    const SizedBox(width: 4),
                    const Text('Live', style: TextStyle(fontSize: 12)),
                  ]),
                ),
                const Divider(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        if (shown.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('No transactions')),
                        for (final e in shown) EntryTile(e),
                      ],
                    ),
                  ),
                ),
              ]),
      ),
    );
  }
}

class _PdfScreen extends StatelessWidget {
  const _PdfScreen(this.data);
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final acc = data['account']['account_no'];
    return Scaffold(
      appBar: AppBar(title: const Text('Passbook PDF')),
      body: PdfPreview(
        build: (_) => buildPassbookPdf(data, brand.name, brand.color),
        pdfFileName: '${brand.flavor}_passbook_$acc.pdf',
        canChangeOrientation: false,
        canChangePageFormat: false,
      ),
    );
  }
}
