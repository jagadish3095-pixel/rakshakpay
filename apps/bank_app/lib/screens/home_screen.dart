import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../brand.dart';
import '../services.dart';
import 'atm_screen.dart';
import 'card_screen.dart';
import 'passbook_screen.dart';
import 'profile_screen.dart';
import 'transfer_screen.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Customer? _customer;
  List<PassbookEntry> _recent = [];
  Object? _error;
  StreamSubscription<String>? _liveSub;

  Account? get _account => _customer?.accounts.firstOrNull;

  @override
  void initState() {
    super.initState();
    _refresh();
    live.start();
    _liveSub = live.changes.listen((no) {
      if (no == _account?.accountNo) _refresh();
    });
  }

  @override
  void dispose() {
    _liveSub?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final me = Customer.fromJson(await api.get('/api/me'));
      final book = await api.get('/api/accounts/${me.accounts.first.accountNo}/passbook');
      final entries = [for (final e in book['entries']) PassbookEntry.fromJson(e)];
      if (!mounted) return;
      setState(() {
        _customer = me;
        _recent = entries.reversed.take(5).toList();
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

  void _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _refresh();
  }

  Future<void> _demoDeposit() async {
    final controller = TextEditingController(text: '50000');
    final amount = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Demo: cash deposit at branch'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: '₹ ', labelText: 'Fake cash amount'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, parsePaise(controller.text)), child: const Text('Deposit')),
        ],
      ),
    );
    if (amount == null) return;
    try {
      await api.post('/api/demo/cash-deposit', {'account_no': _account!.accountNo, 'amount': amount});
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final acc = _account;
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [BankLogo(brand, size: 32), const SizedBox(width: 10), Text(brand.name)]),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => switch (v) {
              'settings' => _open(SettingsScreen(api: api, location: location)),
              'deposit' => _demoDeposit(),
              _ => _logout(),
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'deposit', child: Text('Demo: deposit cash')),
              PopupMenuItem(value: 'settings', child: Text('Settings')),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: acc == null
          ? Center(child: _error != null ? Text(_error.toString()) : const CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Namaste, ${_customer!.fullName.split(' ').first}',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if (!acc.isActive) _RestrictionBanner(acc),
                  _BalanceCard(acc),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      _Action(Icons.send, 'Send money', () => _open(TransferScreen(account: acc))),
                      _Action(Icons.menu_book, 'Passbook', () => _open(PassbookScreen(accountNo: acc.accountNo))),
                      _Action(Icons.atm, 'ATM cash', () => _open(AtmListScreen(account: acc))),
                      _Action(Icons.credit_card, 'Debit card', () => _open(CardScreen(account: acc))),
                      _Action(Icons.person, 'Profile', () => _open(ProfileScreen(customer: _customer!))),
                      _Action(Icons.add_card, 'Demo deposit', _demoDeposit),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Text('Recent transactions', style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    TextButton(
                        onPressed: () => _open(PassbookScreen(accountNo: acc.accountNo)),
                        child: const Text('View all')),
                  ]),
                  if (_recent.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('No transactions yet')),
                  for (final e in _recent) EntryTile(e),
                ],
              ),
            ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard(this.acc);
  final Account acc;

  @override
  Widget build(BuildContext context) {
    const white = TextStyle(color: Colors.white);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: [brand.color, Color.lerp(brand.color, Colors.black, 0.4)!]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('${acc.typeLabel} account', style: white.copyWith(color: Colors.white70)),
            const Spacer(),
            StatusBadge(acc.status),
          ]),
          const SizedBox(height: 4),
          Text('A/c ${acc.accountNo}  •  ${acc.branch.ifsc}', style: white.copyWith(color: Colors.white70)),
          if (acc.isMerchant) Text(acc.businessName, style: white.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Available balance', style: TextStyle(color: Colors.white70)),
          Text(rupees(acc.availableBalance),
              style: white.copyWith(fontSize: 32, fontWeight: FontWeight.bold,
                  color: acc.availableBalance < 0 ? Colors.red.shade100 : Colors.white)),
          if (acc.lienAmount > 0) ...[
            const SizedBox(height: 8),
            Text('Ledger balance ${rupees(acc.balance)}  •  On hold ${rupees(acc.lienAmount)}',
                style: white.copyWith(color: Colors.orange.shade100)),
          ],
        ],
      ),
    );
  }
}

class _RestrictionBanner extends StatelessWidget {
  const _RestrictionBanner(this.acc);
  final Account acc;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: const ListTile(
        leading: Icon(Icons.gpp_bad, color: Colors.red),
        title: Text('Debit services restricted'),
        subtitle: Text('Your account is linked to a cyber fraud complaint. '
            'Visit your home branch with original KYC documents for verification.'),
      ),
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
      color: brand.color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: brand.color, size: 30),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
        ]),
      ),
    );
  }
}

/// One passbook line, used on Home and in the Passbook.
class EntryTile extends StatelessWidget {
  const EntryTile(this.e, {super.key});
  final PassbookEntry e;

  @override
  Widget build(BuildContext context) {
    final color = e.isCredit ? Colors.green.shade700 : Colors.red.shade700;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(e.isCredit ? Icons.south_west : Icons.north_east, color: color),
      ),
      title: Text(e.narration, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
      subtitle: Text([formatDateTime(e.date), if (e.locationLabel.isNotEmpty) e.locationLabel].join('  •  '),
          style: const TextStyle(fontSize: 12)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('${e.isCredit ? '+' : '−'} ${rupees(e.amount)}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          Text('Bal ${rupees(e.balanceAfter)}', style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
