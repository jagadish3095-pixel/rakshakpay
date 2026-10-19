import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';

/// Pick an ATM (nearest first). Any bank's card works at any bank's ATM.
class AtmListScreen extends StatefulWidget {
  const AtmListScreen({super.key, required this.account});
  final Account account;

  @override
  State<AtmListScreen> createState() => _AtmListScreenState();
}

class _AtmListScreenState extends State<AtmListScreen> {
  List<(Atm, double?)> _atms = [];
  String _where = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = [for (final a in await api.get('/api/atms') as List) Atm.fromJson(a)];
      final here = await location.current();
      final withDistance = [
        for (final a in list)
          (a, here.lat == null ? null : LocationService.distanceKm(here.lat!, here.lng!, a.lat, a.lng)),
      ]..sort((x, y) => here.lat == null
          ? '${x.$1.city}${x.$1.name}'.compareTo('${y.$1.city}${y.$1.name}') // no location: by city
          : x.$2!.compareTo(y.$2!)); // nearest first
      setState(() {
        _atms = withDistance;
        _where = here.label;
        _loading = false;
      });
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  String _km(double? d) => d == null ? '' : (d < 1 ? '${(d * 1000).round()} m' : '${d.toStringAsFixed(1)} km');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Withdraw cash at ATM')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(children: [
              ListTile(
                leading: const Icon(Icons.my_location),
                title: const Text('Your location'),
                subtitle: Text(_where),
              ),
              const Divider(),
              for (final (atm, dist) in _atms)
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.atm)),
                  title: Text(atm.name),
                  subtitle: Text('${atm.address}, ${atm.state}'),
                  trailing: Text(_km(dist)),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => AtmMachineScreen(atm: atm, account: widget.account))),
                ),
            ]),
    );
  }
}

/// Looks like an ATM screen: card inserted, choose amount, enter PIN.
class AtmMachineScreen extends StatefulWidget {
  const AtmMachineScreen({super.key, required this.atm, required this.account});
  final Atm atm;
  final Account account;

  @override
  State<AtmMachineScreen> createState() => _AtmMachineScreenState();
}

class _AtmMachineScreenState extends State<AtmMachineScreen> {
  final _amount = TextEditingController();
  final _pin = TextEditingController();
  String? _result;
  bool _ok = false;
  bool _busy = false;

  Future<void> _withdraw() async {
    final amount = parsePaise(_amount.text);
    if (amount == null || _pin.text.length != 4) {
      setState(() => _result = 'Enter amount and 4-digit PIN');
      return;
    }
    setState(() => _busy = true);
    try {
      final res = await api.post('/api/atm/withdraw', {
        'atm_id': widget.atm.id,
        'card_no': widget.account.cardNo,
        'card_pin': _pin.text,
        'amount': amount,
      });
      setState(() {
        _ok = true;
        _result = '${res['message']}\n\nRef ${res['utr']}\nAvailable balance ${rupees(res['available_balance'])}';
      });
    } catch (e) {
      setState(() {
        _ok = false;
        _result = 'TRANSACTION DECLINED\n\n$e';
      });
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const screenText = TextStyle(color: Color(0xFF7CFFB2), fontFamily: 'monospace', fontSize: 16);
    final card = widget.account.cardNo;
    return Scaffold(
      backgroundColor: const Color(0xFF263238),
      appBar: AppBar(title: Text(widget.atm.name), backgroundColor: const Color(0xFF37474F)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1F14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade700, width: 6),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('WELCOME\n${widget.atm.address.toUpperCase()}', style: screenText),
              const SizedBox(height: 12),
              Text('CARD INSERTED: XXXX XXXX XXXX ${card.substring(12)}', style: screenText),
              const SizedBox(height: 12),
              if (_result != null)
                Text(_result!, style: screenText.copyWith(color: _ok ? const Color(0xFF7CFFB2) : Colors.redAccent))
              else
                const Text('SELECT OR ENTER AMOUNT', style: screenText),
            ]),
          ),
          const SizedBox(height: 16),
          if (!_ok) ...[
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final v in [500, 1000, 2000, 5000, 10000, 20000])
                ActionChip(label: Text('₹$v'), onPressed: () => setState(() => _amount.text = '$v')),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white, fontSize: 20),
              decoration: const InputDecoration(
                  labelText: 'Amount (multiples of ₹100, max ₹20,000)', prefixText: '₹ ',
                  labelStyle: TextStyle(color: Colors.white70), prefixStyle: TextStyle(color: Colors.white),
                  filled: true, fillColor: Colors.black26),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pin,
              obscureText: true,
              maxLength: 4,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 12),
              decoration: const InputDecoration(
                  labelText: 'ATM PIN', labelStyle: TextStyle(color: Colors.white70),
                  counterStyle: TextStyle(color: Colors.white54), filled: true, fillColor: Colors.black26),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: Colors.green.shade700),
              onPressed: _busy ? null : _withdraw,
              icon: const Icon(Icons.payments),
              label: Text(_busy ? 'Processing…' : 'Withdraw cash'),
            ),
          ] else
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Take card & exit')),
        ],
      ),
    );
  }
}
