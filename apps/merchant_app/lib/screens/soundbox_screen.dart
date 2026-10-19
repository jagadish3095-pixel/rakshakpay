import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../announcer.dart';
import '../services.dart';
import 'login_screen.dart';

/// The shop counter screen: big QR code, today's collection, and every new
/// payment announced aloud.
class SoundboxScreen extends StatefulWidget {
  const SoundboxScreen({super.key});

  @override
  State<SoundboxScreen> createState() => _SoundboxScreenState();
}

class _SoundboxScreenState extends State<SoundboxScreen> {
  UpiProfile? _profile;
  UpiVpa? _shop;
  List<UpiPayment> _today = [];
  final _seen = <String>{};
  UpiPayment? _flash; // newest payment, highlighted for a few seconds
  Object? _error;
  StreamSubscription<String>? _liveSub;
  Timer? _poll;
  bool _firstLoad = true;

  List<UpiVpa> get _shops => _profile?.vpas.where((v) => v.isMerchant).toList() ?? [];

  @override
  void initState() {
    super.initState();
    _refresh();
    live.start();
    _liveSub = live.changes.listen((_) => _refresh());
    // Backup in case the live connection drops on shop Wi-Fi.
    _poll = Timer.periodic(const Duration(seconds: 20), (_) => _refresh());
  }

  @override
  void dispose() {
    _liveSub?.cancel();
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final profile = await loadProfile();
      final shops = profile.vpas.where((v) => v.isMerchant).toList();
      final saved = api.prefs.getString('merchant.vpa');
      final shop = shops.where((v) => v.address == (_shop?.address ?? saved)).firstOrNull ?? shops.firstOrNull;
      var today = <UpiPayment>[];
      if (shop != null) {
        final all = [for (final p in await api.get('/api/upi/history') as List) UpiPayment.fromJson(p)];
        final now = DateTime.now();
        today = all.where((p) {
          final d = DateTime.parse(p.date);
          return !p.sent && p.myVpa == shop.address && d.year == now.year && d.month == now.month && d.day == now.day;
        }).toList();
        _announceNew(all.where((p) => !p.sent && p.myVpa == shop.address));
      }
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _shop = shop;
        _today = today;
        _error = null;
        _firstLoad = false;
      });
    } on ApiException catch (e) {
      if (e.statusCode == 401) return _logout();
      if (mounted) setState(() => _error = e);
    }
  }

  /// Speak payments we have not seen yet (not the old ones on first load).
  void _announceNew(Iterable<UpiPayment> received) {
    final fresh = received.where((p) => !_seen.contains(p.utr)).toList().reversed; // oldest first
    for (final p in fresh) {
      _seen.add(p.utr);
      if (_firstLoad) continue;
      announcer.paymentReceived(p.amount);
      _flash = p;
      Future.delayed(const Duration(seconds: 6), () {
        if (mounted && _flash == p) setState(() => _flash = null);
      });
    }
  }

  Future<void> _logout() async {
    live.stop();
    await api.setToken(null);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  Future<void> _chooseLanguage() async {
    final lang = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Announcement language'),
        children: [
          RadioGroup<String>(
            groupValue: announcer.language,
            onChanged: (v) => Navigator.pop(ctx, v),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (final e in kLanguages.entries) RadioListTile<String>(value: e.key, title: Text(e.value)),
            ]),
          ),
        ],
      ),
    );
    if (lang == null) return;
    await announcer.setLanguage(lang);
    if (!await announcer.languageAvailable(lang) && mounted) {
      showError(context, 'This phone has no ${kLanguages[lang]} voice installed, so English will be used. '
          'Install it in phone Settings > Text-to-speech.');
    }
    setState(() {});
    announcer.test();
  }

  @override
  Widget build(BuildContext context) {
    final shop = _shop;
    final total = _today.fold<int>(0, (sum, p) => sum + p.amount);
    return Scaffold(
      appBar: AppBar(
        title: Text(shop?.displayName ?? 'RakshakPay Business'),
        actions: [
          IconButton(
            tooltip: announcer.enabled ? 'Sound on' : 'Sound off',
            icon: Icon(announcer.enabled ? Icons.volume_up : Icons.volume_off),
            onPressed: () async {
              await announcer.setEnabled(!announcer.enabled);
              setState(() {});
            },
          ),
          PopupMenuButton<String>(
            onSelected: (v) => switch (v) {
              'lang' => _chooseLanguage(),
              'test' => announcer.test(),
              'settings' => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => SettingsScreen(api: api, location: location))),
              _ => _logout(),
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'lang', child: Text('Language: ${kLanguages[announcer.language]}')),
              const PopupMenuItem(value: 'test', child: Text('Test sound')),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
              const PopupMenuItem(value: 'logout', child: Text('Log out')),
            ],
          ),
        ],
      ),
      body: _profile == null
          ? Center(child: _error != null ? Text(_error.toString()) : const CircularProgressIndicator())
          : shop == null
              ? _noShop()
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                    if (_shops.length > 1)
                      DropdownButtonFormField<String>(
                        initialValue: shop.address,
                        decoration: const InputDecoration(labelText: 'Shop'),
                        items: [for (final s in _shops) DropdownMenuItem(value: s.address, child: Text(s.displayName))],
                        onChanged: (v) async {
                          await api.prefs.setString('merchant.vpa', v!);
                          setState(() => _shop = _shops.firstWhere((s) => s.address == v));
                          _refresh();
                        },
                      ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _flash == null
                          ? const SizedBox.shrink()
                          : Card(
                              key: ValueKey(_flash!.utr),
                              color: Colors.green.shade600,
                              child: ListTile(
                                leading: const Icon(Icons.volume_up, color: Colors.white, size: 36),
                                title: Text('${rupees(_flash!.amount)} received',
                                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                subtitle: Text('from ${_flash!.otherName}', style: const TextStyle(color: Colors.white)),
                              ),
                            ),
                    ),
                    Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(children: [
                          Text(shop.displayName, style: Theme.of(context).textTheme.headlineSmall),
                          Text(BankBrand.byCode(shop.bankCode).name,
                              style: TextStyle(color: BankBrand.byCode(shop.bankCode).color)),
                          const SizedBox(height: 12),
                          QrImageView(
                            data: buildUpiUri(vpa: shop.address, name: shop.displayName),
                            size: 260,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Text(shop.address, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const Text('Scan with any UPI app to pay'),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      color: kIndigo,
                      child: ListTile(
                        title: const Text("Today's collection", style: TextStyle(color: Colors.white70)),
                        subtitle: Text(rupees(total),
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        trailing: Text('${_today.length}\npayments', textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text("Today's payments", style: Theme.of(context).textTheme.titleMedium),
                    if (_today.isEmpty)
                      const Padding(padding: EdgeInsets.all(16), child: Text('No payments yet today')),
                    for (final p in _today)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(child: Icon(Icons.south_west)),
                        title: Text(p.otherName),
                        subtitle: Text('${p.otherVpa}\n${formatDateTime(p.date)}'),
                        isThreeLine: true,
                        trailing: Text('+ ${rupees(p.amount)}',
                            style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                      ),
                  ]),
                ),
    );
  }

  Widget _noShop() => ListView(padding: const EdgeInsets.all(24), children: [
        const Icon(Icons.storefront, size: 72, color: kIndigo),
        const SizedBox(height: 12),
        Text('No merchant account linked', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        const Text('1. In any bank app, open a new account and choose "Current / Merchant" '
            '(use this same mobile number).\n'
            '2. In the RakshakPay app, tap "Link bank" and link that account.\n'
            '3. Come back here and pull down to refresh.'),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('Refresh')),
      ]);
}
