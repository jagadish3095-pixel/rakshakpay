import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../models.dart';
import '../services.dart';
import '../theme.dart';
import 'accounts_screen.dart';
import 'history_screen.dart';
import 'link_bank_screen.dart';
import 'my_qr_screen.dart';
import 'pay_screen.dart';
import 'scan_screen.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UpiProfile? _profile;
  List<UpiPayment> _recent = [];
  Object? _error;
  StreamSubscription<String>? _liveSub;

  @override
  void initState() {
    super.initState();
    _refresh(firstLoad: true);
    live.start();
    _liveSub = live.changes.listen((_) => _refresh());
  }

  @override
  void dispose() {
    _liveSub?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool firstLoad = false}) async {
    try {
      final profile = await loadProfile();
      final history = [for (final p in await api.get('/api/upi/history') as List) UpiPayment.fromJson(p)];
      if (!mounted) return;
      final newest = history.firstOrNull;
      // Pop-up when money arrives while the app is open.
      if (!firstLoad && newest != null && newest.utr != _recent.firstOrNull?.utr && !newest.sent) {
        showInfo(context, '${rupees(newest.amount)} received from ${newest.otherName}');
      }
      setState(() {
        _profile = profile;
        _recent = history.take(5).toList();
        _error = null;
      });
    } on ApiException catch (e) {
      if (e.statusCode == 401) return _logout();
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _logout() async {
    live.stop();
    await api.setToken(null);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()), (_) => false);
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [RakshakLogo(size: 30, onDark: true), SizedBox(width: 8), Text('RakshakPay')]),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => v == 'settings' ? _open(SettingsScreen(api: api, location: location)) : _logout(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'settings', child: Text('Settings')),
              PopupMenuItem(value: 'logout', child: Text('Log out')),
            ],
          ),
        ],
      ),
      body: p == null
          ? Center(child: _error != null ? Text(_error.toString()) : const CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ProfileCard(p, onLink: () => _open(const LinkBankScreen())),
                  const SizedBox(height: 16),
                  if (p.vpas.isNotEmpty) ...[
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: kSaffron, padding: const EdgeInsets.symmetric(vertical: 18)),
                      onPressed: () => _open(ScanScreen(profile: p)),
                      icon: const Icon(Icons.qr_code_scanner, size: 28),
                      label: const Text('Scan & Pay', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: [
                        _Action(Icons.alternate_email, 'Pay UPI ID\nor mobile', () => _open(PayScreen(profile: p))),
                        _Action(Icons.qr_code_2, 'My QR', () => _open(MyQrScreen(profile: p))),
                        _Action(Icons.account_balance_wallet, 'Check\nbalance',
                            () => _open(AccountsScreen(profile: p, askBalance: true))),
                        _Action(Icons.account_balance, 'Bank\naccounts', () => _open(AccountsScreen(profile: p))),
                        _Action(Icons.history, 'History', () => _open(const HistoryScreen())),
                        _Action(Icons.add_link, 'Link bank', () => _open(const LinkBankScreen())),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      Text('Recent payments', style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      TextButton(onPressed: () => _open(const HistoryScreen()), child: const Text('See all')),
                    ]),
                    if (_recent.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('No payments yet')),
                    for (final pay in _recent) PaymentTile(pay),
                  ],
                ],
              ),
            ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard(this.p, {required this.onLink});
  final UpiProfile p;
  final VoidCallback onLink;

  @override
  Widget build(BuildContext context) {
    final vpa = p.primary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [kIndigo, Color(0xFF1E1550)]),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Namaste, ${p.name.split(' ').first}',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        Text('+91 ${p.mobile}', style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 12),
        if (vpa == null) ...[
          const Text('Link a bank account to start paying with UPI.', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: kSaffron),
            onPressed: onLink,
            icon: const Icon(Icons.add_link),
            label: const Text('Link bank account'),
          ),
        ] else
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: vpa.address));
              showInfo(context, 'UPI ID copied');
            },
            child: Row(children: [
              const Text('UPI ID  ', style: TextStyle(color: Colors.white70)),
              Flexible(
                child: Text(vpa.address,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.copy, size: 16, color: Colors.white70),
            ]),
          ),
      ]),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kIndigo.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: kIndigo, size: 28),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        ]),
      ),
    );
  }
}

/// One UPI payment row, used on Home and History.
class PaymentTile extends StatelessWidget {
  const PaymentTile(this.p, {super.key});
  final UpiPayment p;

  @override
  Widget build(BuildContext context) {
    final color = p.sent ? Colors.red.shade700 : Colors.green.shade700;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: kIndigo.withValues(alpha: 0.1),
        child: Text(p.otherName.isEmpty ? '?' : p.otherName[0], style: const TextStyle(color: kIndigo)),
      ),
      title: Text(p.sent ? 'Paid to ${p.otherName}' : 'Received from ${p.otherName}'),
      subtitle: Text('${p.otherVpa}\n${formatDateTime(p.date)}', style: const TextStyle(fontSize: 12)),
      isThreeLine: true,
      trailing: Text('${p.sent ? '−' : '+'} ${rupees(p.amount)}',
          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }
}
