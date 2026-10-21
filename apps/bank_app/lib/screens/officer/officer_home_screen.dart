import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../../services.dart';
import '../welcome_screen.dart';
import 'customer_desk_screen.dart';

/// Branch desk: find customers, see who is on the mule list, track verifications.
class OfficerHomeScreen extends StatefulWidget {
  const OfficerHomeScreen({super.key});

  @override
  State<OfficerHomeScreen> createState() => _OfficerHomeScreenState();
}

class _OfficerHomeScreenState extends State<OfficerHomeScreen> {
  Map<String, dynamic>? _me;
  final _q = TextEditingController();
  List<Map<String, dynamic>>? _results;
  List<Map<String, dynamic>>? _flagged;
  List<Map<String, dynamic>>? _cases;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final me = await officerApi.get('/api/officer/me');
      final flagged = (await officerApi.get('/api/officer/flagged') as List).cast<Map<String, dynamic>>();
      final cases = (await officerApi.get('/api/officer/verifications') as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _me = me;
        _flagged = flagged;
        _cases = cases;
      });
    } on ApiException catch (e) {
      if (e.statusCode == 401) return _logout();
      if (mounted) showError(context, e);
    }
  }

  Future<void> _search() async {
    try {
      final r = (await officerApi.get('/api/officer/search', {'q': _q.text}) as List).cast<Map<String, dynamic>>();
      setState(() => _results = r);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _logout() async {
    await officerApi.setToken(null);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()), (_) => false);
  }

  Future<void> _open(String cif) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerDeskScreen(cif: cif)));
    _load();
    if (_results != null) _search();
  }

  Widget _customerTile(Map<String, dynamic> c) => Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: c['flagged'] == true ? chipBg(context, Colors.red) : brand.color.withValues(alpha: 0.15),
            child: Icon(c['flagged'] == true ? Icons.gpp_bad : Icons.person,
                color: c['flagged'] == true ? Colors.red : brand.color),
          ),
          title: Text(c['name']),
          subtitle: Text('CIF ${c['cif']} • ${c['mobile']} • PAN ${c['pan']}'
              '${c['lien'] != null && c['lien'] > 0 ? '\n${tr('On hold {amount}', {'amount': rupees(c['lien'])})}' : ''}'),
          trailing: c['flagged'] == true ? const StatusBadge('SUSPECTED_MULE') : const Icon(Icons.chevron_right),
          onTap: () => _open(c['cif']),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final me = _me;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(me == null ? tr('Branch desk') : '${me['name']} • ${me['branch']}'),
          actions: [IconButton(tooltip: tr('Log out'), onPressed: _logout, icon: const Icon(Icons.logout))],
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [Tab(text: tr('Search')), Tab(text: tr('Mule list')), Tab(text: tr('Verifications'))],
          ),
        ),
        body: TabBarView(children: [
          ListView(padding: const EdgeInsets.all(16), children: [
            TextField(
              controller: _q,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                labelText: tr('Account no, mobile, PAN, Customer ID or name'),
                suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _search),
              ),
            ),
            const SizedBox(height: 12),
            if (_results != null && _results!.isEmpty) Text(tr('No customer found in this bank')),
            for (final c in _results ?? const []) _customerTile(c),
          ]),
          RefreshIndicator(
            onRefresh: _load,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Text(tr('Customers of this bank on the mule list or with money on hold. '
                  'They must visit the branch for verification.')),
              const SizedBox(height: 8),
              if (_flagged?.isEmpty ?? false) Text(tr('Nobody is flagged')),
              for (final c in _flagged ?? const []) _customerTile(c),
            ]),
          ),
          RefreshIndicator(
            onRefresh: _load,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              if (_cases?.isEmpty ?? false) Text(tr('No verifications yet')),
              for (final c in _cases ?? const []) VerificationCaseCard(c, onTap: () => _open(c['cif'])),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Status of one branch verification (also shown on the customer desk).
class VerificationCaseCard extends StatelessWidget {
  const VerificationCaseCard(this.c, {super.key, this.onTap});
  final Map<String, dynamic> c;
  final VoidCallback? onTap;

  static (String, Color) decisionLook(String? d) => switch (d) {
        'INNOCENT' => (tr('Innocent – delisted'), Colors.green),
        'TRICKED' => (tr('Tricked – restored with conditions'), Colors.orange),
        'INVOLVED' => (tr('Involved – confirmed mule'), Colors.red),
        _ => (tr('Waiting for police'), Colors.blueGrey),
      };

  @override
  Widget build(BuildContext context) {
    final (label, color) = decisionLook(c['decision']);
    final recommendation = switch (c['recommendation']) {
      'INNOCENT' => tr('Innocent'),
      'TRICKED' => tr('Tricked'),
      'INVOLVED' => tr('Knowingly involved'),
      final r => '$r',
    };
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.fact_check, color: color),
        title: Text('${c['customer']} • ${tr('A/c {account}', {'account': c['account_no']})}'),
        subtitle: Text('${c['reason_category']}\n'
            '${tr('Officer: {recommendation}', {'recommendation': recommendation})} • ${formatDateTime(c['date'])}'
            '${(c['police_remarks'] as String).isNotEmpty ? '\n${tr('Police: {remarks}', {'remarks': c['police_remarks']})}' : ''}'),
        isThreeLine: true,
        trailing: Chip(label: Text(label, style: TextStyle(color: color, fontSize: 11)), side: BorderSide(color: color)),
      ),
    );
  }
}
