import 'dart:async';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../passbook_pdf.dart';
import '../services.dart';
import 'home_screen.dart' show EntryTile;

/// Full passbook. Updates by itself when money comes in or goes out.
class PassbookScreen extends StatefulWidget {
  const PassbookScreen({super.key, required this.accountNo, this.reportMode = false});
  final String accountNo;

  /// Opened from "Report fraud": show debits and explain what to tap.
  final bool reportMode;

  @override
  State<PassbookScreen> createState() => _PassbookScreenState();
}

class _PassbookScreenState extends State<PassbookScreen> {
  Map<String, dynamic>? _data;
  List<PassbookEntry> _entries = [];
  late String _filter = widget.reportMode ? 'DR' : 'ALL';

  static const _reportable = {'IMPS', 'NEFT', 'INTERNAL', 'UPI'};

  /// "IMPS/DR/RAVI KUMAR/GNGA/123..." -> "RAVI KUMAR"
  String _payee(PassbookEntry e) {
    final parts = e.narration.split('/');
    return parts.length > 2 ? parts[2] : e.narration;
  }

  void _details(PassbookEntry e) {
    final canReport = !e.isCredit && _reportable.contains(e.channel);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.isCredit
                    ? tr('Credit {amount}', {'amount': rupees(e.amount)})
                    : tr('Debit {amount}', {'amount': rupees(e.amount)}),
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(e.narration),
            Text('UTR ${e.utr} • ${e.channel}'),
            Text(formatDateTime(e.date)),
            if (e.locationLabel.isNotEmpty) Text(tr('Location: {place}', {'place': e.locationLabel})),
            if (e.remark.isNotEmpty) Text(tr('Remark: {remark}', {'remark': e.remark})),
            const SizedBox(height: 16),
            if (canReport)
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ReportFraudScreen(
                      api: api, location: location, postPath: '/api/complaints',
                      utr: e.utr, amount: e.amount, paidTo: _payee(e), date: e.date),
                  ));
                },
                icon: const Icon(Icons.report),
                label: Text(tr('Report this payment as fraud (1930)')),
              ),
          ]),
        ),
      ),
    );
  }
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
        title: Text(tr('Passbook')),
        actions: [
          IconButton(
            tooltip: tr('Download PDF'),
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _data == null
                ? null
                : () => Navigator.push(context, MaterialPageRoute(builder: (_) => _PdfScreen(_data!))),
          ),
        ],
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: _flash ? chipBg(context, Colors.yellow) : Colors.transparent,
        child: account == null
            ? const Center(child: CircularProgressIndicator())
            : Column(children: [
                ListTile(
                  title: Text(tr('A/c {account}', {'account': account.accountNo})),
                  subtitle: Text('${account.holderName} • ${account.branch.ifsc}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(tr('Balance'), style: const TextStyle(fontSize: 12)),
                      Text(rupees(account.balance), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    for (final (key, label) in [('ALL', tr('All')), ('CR', tr('Credits')), ('DR', tr('Debits'))])
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
                    Text(tr('Live'), style: const TextStyle(fontSize: 12)),
                  ]),
                ),
                const Divider(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        if (shown.isEmpty)
                          Padding(padding: const EdgeInsets.all(24), child: Text(tr('No transactions'))),
                        if (widget.reportMode)
                          Card(
                            color: softBg(context, Colors.red),
                            child: ListTile(
                              leading: const Icon(Icons.report, color: Colors.red),
                              title: Text(tr('Which payment was fraud?')),
                              subtitle: Text(tr('Tap the payment to report it.')),
                            ),
                          ),
                        for (final e in shown) EntryTile(e, onTap: () => _details(e)),
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
      appBar: AppBar(title: Text(tr('Passbook PDF'))),
      body: PdfPreview(
        build: (_) => buildPassbookPdf(data, brand.name, brand.color),
        pdfFileName: '${brand.flavor}_passbook_$acc.pdf',
        canChangeOrientation: false,
        canChangePageFormat: false,
      ),
    );
  }
}
