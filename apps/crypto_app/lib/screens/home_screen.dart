import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../brand.dart';
import '../models.dart';
import '../services.dart';
import 'coin_screen.dart';
import 'deposit_screen.dart';
import 'history_screen.dart';
import 'welcome_screen.dart';
import 'withdraw_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  CryptoProfile? _profile;
  Map<String, PriceTick> _prices = {};
  Object? _error;
  Timer? _ticker;
  StreamSubscription<String>? _liveSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    live.start();
    _liveSub = live.changes.listen((_) => _refresh());
    // Prices move every few seconds.
    _ticker = Timer.periodic(const Duration(seconds: 5), (_) => _refreshPrices());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _liveSub?.cancel();
    super.dispose();
  }

  /// Coming back from RakshakPay after a deposit: show the new balance.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    try {
      final p = await loadProfile();
      final prices = await loadPrices();
      if (!mounted) return;
      setState(() {
        _profile = p;
        _prices = {for (final t in prices) t.asset: t};
        _error = null;
      });
    } on ApiException catch (e) {
      if (e.statusCode == 401) return _logout();
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _refreshPrices() async {
    try {
      final prices = await loadPrices();
      if (mounted) setState(() => _prices = {for (final t in prices) t.asset: t});
    } catch (_) {}
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

  int _value(Holding h) => h.quantity * (_prices[h.asset]?.price ?? h.price) ~/ kUnits;

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    final total = p == null ? 0 : p.inr + p.holdings.fold<int>(0, (s, h) => s + _value(h));
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [CoinVaultLogo(size: 30), SizedBox(width: 8), Text('CoinVault')]),
        actions: [
          IconButton(tooltip: tr('History'), icon: const Icon(Icons.receipt_long), onPressed: () => _open(const HistoryScreen())),
          PopupMenuButton<String>(
            onSelected: (v) => switch (v) {
              'settings' => _open(SettingsScreen(api: api, location: location, makesPayments: false)),
              'pin' => _open(ChangeSecretScreen(
                  title: tr('Change CoinVault PIN'),
                  what: 'PIN',
                  submit: (current, next) async {
                    await api.post('/api/crypto/pin', {'current': current, 'new': next});
                    if (_profile != null) await savedLogins.updatePassword(_profile!.mobile, next);
                  },
                )),
              _ => _logout(),
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'pin', child: Text(tr('Change PIN'))),
              PopupMenuItem(value: 'settings', child: Text(tr('Settings'))),
              PopupMenuItem(value: 'logout', child: Text(tr('Log out'))),
            ],
          ),
        ],
      ),
      body: p == null
          ? Center(child: _error != null ? Text(_error.toString()) : const CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                Text(tr('Hi, {name}', {'name': p.name.split(' ').first}), style: TextStyle(color: muted(context))),
                Text(tr('Portfolio value'), style: TextStyle(color: muted(context))),
                Text(rupees(total), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(tr('INR wallet'), style: TextStyle(color: muted(context))),
                      Text(rupees(p.inr),
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: goldText(context))),
                      Text(tr('Linked bank: {bank} {account}', {'bank': p.bankName, 'account': p.bankAccountMasked}),
                          style: TextStyle(color: muted(context), fontSize: 12)),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _open(DepositScreen(profile: p)),
                            icon: const Icon(Icons.add),
                            label: Text(tr('Deposit')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _open(WithdrawScreen(profile: p)),
                            icon: const Icon(Icons.account_balance),
                            label: Text(tr('Withdraw')),
                          ),
                        ),
                      ]),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                Text(tr('Markets'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                for (final h in p.holdings) _coinTile(h),
              ]),
            ),
    );
  }

  Widget _coinTile(Holding h) {
    final tick = _prices[h.asset];
    final info = CoinInfo.all[h.asset]!;
    final up = (tick?.changePct ?? 0) >= 0;
    return Card(
      child: ListTile(
        leading: CoinIcon(h.asset),
        title: Text(info.name),
        subtitle: Text(h.quantity == 0 ? h.asset : '${formatQty(h.quantity)} ${h.asset} • ${rupees(_value(h))}'),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(rupees(tick?.price ?? h.price), style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('${up ? '▲' : '▼'} ${tick?.changePct.abs().toStringAsFixed(2) ?? '0.00'}%',
              style: TextStyle(color: strong(context, up ? Colors.green : Colors.red), fontSize: 12)),
        ]),
        onTap: () => _open(CoinScreen(asset: h.asset)),
      ),
    );
  }
}
