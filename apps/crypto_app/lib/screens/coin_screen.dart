import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../brand.dart';
import '../models.dart';
import '../services.dart';

/// One coin: live price, your holding, and Buy / Sell / Send to outside wallet.
class CoinScreen extends StatefulWidget {
  const CoinScreen({super.key, required this.asset});
  final String asset;

  @override
  State<CoinScreen> createState() => _CoinScreenState();
}

class _CoinScreenState extends State<CoinScreen> {
  CryptoProfile? _profile;
  PriceTick? _tick;
  String _mode = 'BUY';
  final _inr = TextEditingController();
  final _qty = TextEditingController();
  final _address = TextEditingController();
  bool _busy = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 5), (_) => _loadPrice());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final p = await loadProfile();
      if (mounted) setState(() => _profile = p);
      await _loadPrice();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _loadPrice() async {
    try {
      final t = (await loadPrices()).firstWhere((t) => t.asset == widget.asset);
      if (mounted) setState(() => _tick = t);
    } catch (_) {}
  }

  int get _price => _tick?.price ?? _profile?.holding(widget.asset).price ?? 0;
  int get _held => _profile?.holding(widget.asset).quantity ?? 0;

  Future<void> _submit() async {
    final String path, summary;
    final Map<String, dynamic> body;
    switch (_mode) {
      case 'BUY':
        final inr = parsePaise(_inr.text);
        if (inr == null) return showError(context, tr('Enter an amount'));
        path = '/api/crypto/buy';
        body = {'asset': widget.asset, 'inr': inr};
        summary = tr('Buy {asset} for {amount}', {'asset': widget.asset, 'amount': rupees(inr)});
      case 'SELL':
        final q = parseQty(_qty.text);
        if (q == null) return showError(context, tr('Enter a quantity'));
        path = '/api/crypto/sell';
        body = {'asset': widget.asset, 'quantity': q};
        summary = tr('Sell {qty} {asset}', {'qty': formatQty(q), 'asset': widget.asset});
      default:
        final q = parseQty(_qty.text);
        if (q == null) return showError(context, tr('Enter a quantity'));
        path = '/api/crypto/withdraw-crypto';
        body = {'asset': widget.asset, 'quantity': q, 'address': _address.text.trim()};
        summary = tr('Send {qty} {asset} to an outside wallet', {'qty': formatQty(q), 'asset': widget.asset});
    }
    final pin = await askPin(context, title: tr('Enter CoinVault PIN'), subtitle: summary);
    if (pin == null) return;
    setState(() => _busy = true);
    try {
      final res = await api.post(path, {...body, 'pin': pin});
      if (!mounted) return;
      showInfo(context, res['message']);
      _inr.clear();
      _qty.clear();
      _address.clear();
      setState(() => _profile = CryptoProfile.fromJson(res['user']));
      _loadPrice();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = CoinInfo.all[widget.asset]!;
    final p = _profile;
    final up = (_tick?.changePct ?? 0) >= 0;
    return Scaffold(
      appBar: AppBar(title: Text(info.name)),
      body: p == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(20), children: [
              Row(children: [
                CoinIcon(widget.asset, size: 56),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(rupees(_price), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  Text(
                      tr('{arrow} {pct}% (1 hour)', {
                        'arrow': up ? '▲' : '▼',
                        'pct': _tick?.changePct.abs().toStringAsFixed(2) ?? '0.00',
                      }),
                      style: TextStyle(color: strong(context, up ? Colors.green : Colors.red))),
                ]),
              ]),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  title: Text(tr('You hold')),
                  subtitle: Text('${formatQty(_held)} ${widget.asset}'),
                  trailing: Text(rupees(_held * _price ~/ kUnits), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              Card(
                child: ListTile(
                  title: Text(tr('INR wallet')),
                  trailing: Text(rupees(p.inr), style: TextStyle(color: goldText(context), fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'BUY', label: Text(tr('Buy'))),
                  ButtonSegment(value: 'SELL', label: Text(tr('Sell'))),
                  ButtonSegment(value: 'SEND', label: Text(tr('Send'))),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
              const SizedBox(height: 16),
              ..._form(),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: _mode == 'SEND' ? Colors.deepOrange : null,
                ),
                onPressed: _busy ? null : _submit,
                child: Text(_busy ? tr('Please wait…') : {'BUY': tr('Buy'), 'SELL': tr('Sell'), 'SEND': tr('Send')}[_mode]!),
              ),
            ]),
    );
  }

  List<Widget> _form() {
    final maxQty = TextButton(onPressed: () => setState(() => _qty.text = formatQty(_held)), child: Text(tr('MAX')));
    switch (_mode) {
      case 'BUY':
        final inr = parsePaise(_inr.text) ?? 0;
        return [
          TextField(
            controller: _inr,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: tr('Spend (min ₹100)'), prefixText: '₹ '),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Text(
              tr('You get ≈ {amount}', {
                'amount': '${_price == 0 ? 0 : formatQty(inr * kUnits ~/ _price)} ${widget.asset}',
              }),
              style: TextStyle(color: muted(context))),
        ];
      case 'SELL':
        final q = parseQty(_qty.text) ?? 0;
        return [
          TextField(
            controller: _qty,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: tr('Quantity ({asset})', {'asset': widget.asset}), suffixIcon: maxQty),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Text(tr('You get ≈ {amount}', {'amount': rupees(q * _price ~/ kUnits)}),
              style: TextStyle(color: muted(context))),
        ];
      default:
        return [
          Card(
            color: softBg(context, Colors.deepOrange),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(tr('Coins sent to an outside wallet leave CoinVault. They cannot be frozen, '
                  'reversed or recovered by CoinVault, your bank or the police.')),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _qty,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: tr('Quantity ({asset})', {'asset': widget.asset}), suffixIcon: maxQty),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _address,
            decoration: InputDecoration(
              labelText: tr('Outside wallet address'),
              hintText: tr('e.g. {example}', {'example': 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh'}),
            ),
          ),
        ];
    }
  }
}
