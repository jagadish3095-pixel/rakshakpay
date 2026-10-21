import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';

const _osmUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _userAgent = 'in.rakshakpay.police_app';

/// Base map of India (OpenStreetMap tiles; needs internet).
TileLayer osmTiles() => TileLayer(
      urlTemplate: _osmUrl,
      userAgentPackageName: _userAgent,
      // Show tiles as soon as they load (the default fade-in animation can stall on some browsers).
      tileDisplay: const TileDisplay.instantaneous(),
    );

LatLng? _point(dynamic place) =>
    place == null ? null : LatLng((place['lat'] as num).toDouble(), (place['lng'] as num).toDouble());

/// Where each account was when it handled the victim's money.
///
/// Every payment carries the payer's phone GPS, so:
/// senders are shown where their phone was for their first (non-ATM) payment in the trail;
/// a shop is shown where the buyer's phone was when paying it (the buyer was at the counter);
/// others at the last place the account was used (phone or ATM). The home branch is only a
/// fallback, and the online exchange always sits at its branch.
Map<String, LatLng> nodePositions(Map<String, dynamic> d) {
  final edges = (d['edges'] as List).cast<Map<String, dynamic>>();
  final nodes = (d['nodes'] as List).cast<Map<String, dynamic>>();
  final pos = <String, LatLng>{};
  for (final n in nodes) {
    final no = n['account_no'] as String;
    final out = edges.where((e) => e['from_account'] == no && e['kind'] != 'ATM' && e['location'] != null);
    final paidIn = edges.where((e) => e['to_account'] == no && e['location'] != null);
    pos[no] = switch (n['role']) {
      'EXCHANGE' => _point(n['home'])!,
      'MERCHANT' => _point(paidIn.firstOrNull?['location']) ?? _point(n['home'])!,
      _ => _point(out.firstOrNull?['location']) ?? _point(n['last_seen']) ?? _point(n['home'])!,
    };
  }
  // Spread out accounts that sit on (almost) the same spot so every pin is visible.
  final groups = <String, List<String>>{};
  pos.forEach((no, p) => groups.putIfAbsent('${p.latitude.toStringAsFixed(1)},${p.longitude.toStringAsFixed(1)}', () => []).add(no));
  for (final g in groups.values.where((g) => g.length > 1)) {
    for (var i = 0; i < g.length; i++) {
      final a = 2 * pi * i / g.length;
      final p = pos[g[i]]!;
      pos[g[i]] = LatLng(p.latitude + 0.18 * sin(a), p.longitude + 0.18 * cos(a));
    }
  }
  return pos;
}

/// Complaint map: pins for every account and ATM, arrows for every hop, and a
/// Play button that replays the money moving in time order.
class TrailMap extends StatefulWidget {
  const TrailMap(this.detail, {super.key});
  final Map<String, dynamic> detail;

  @override
  State<TrailMap> createState() => _TrailMapState();
}

class _TrailMapState extends State<TrailMap> {
  late List<Map<String, dynamic>> _edges;
  late Map<String, Map<String, dynamic>> _nodes;
  late Map<String, LatLng> _pos;
  late int _shown; // how many hops are visible (all by default)
  Timer? _player;
  final _map = MapController();

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  List<LatLng> get _allPoints => [..._pos.values, for (final e in _edges) _ends(e).$2];

  /// Fit all pins once the map knows its real size (inside tabs it starts at size 0,
  /// and without this the tiles do not load until the user moves the map).
  void _fit() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _map.fitCamera(CameraFit.coordinates(coordinates: _allPoints, padding: const EdgeInsets.all(48)));
      });

  @override
  void didUpdateWidget(TrailMap old) {
    super.didUpdateWidget(old);
    if (old.detail != widget.detail) _prepare();
  }

  void _prepare() {
    _edges = (widget.detail['edges'] as List).cast<Map<String, dynamic>>().toList()
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    _nodes = {for (final n in (widget.detail['nodes'] as List).cast<Map<String, dynamic>>()) n['account_no']: n};
    _pos = nodePositions(widget.detail);
    _shown = _edges.length;
  }

  @override
  void dispose() {
    _player?.cancel();
    super.dispose();
  }

  void _play() {
    _player?.cancel();
    setState(() => _shown = 0);
    _player = Timer.periodic(const Duration(milliseconds: 1200), (t) {
      if (_shown >= _edges.length) return t.cancel();
      setState(() => _shown++);
    });
  }

  /// Where a hop starts and ends on the map.
  (LatLng, LatLng) _ends(Map<String, dynamic> e) {
    final from = _pos[e['from_account']]!;
    final to = e['kind'] == 'ATM' ? (_point(e['location']) ?? from) : _pos[e['to_account']]!;
    return (from, to);
  }

  /// Display name of a hop kind code sent by the server.
  static String _kindLabel(Object? kind) => switch (kind) {
        'TRANSFER' => tr('Transfer'),
        'ATM' => tr('ATM cash'),
        'MERCHANT' => tr('Merchant purchase'),
        'CRYPTO' => tr('To crypto exchange'),
        'RETURN' => tr('Returned'),
        _ => '$kind',
      };

  static Color _edgeColor(String kind) => switch (kind) {
        'ATM' => Colors.black87,
        'MERCHANT' => Colors.green.shade700,
        'CRYPTO' => Colors.purple,
        _ => Colors.red.shade600,
      };

  @override
  Widget build(BuildContext context) {
    final visible = _edges.take(_shown).toList();
    final shownAccounts = <String>{
      ..._nodes.values.where((n) => n['role'] == 'VICTIM').map((n) => n['account_no'] as String),
      for (final e in visible) e['from_account'] as String,
      for (final e in visible)
        if (e['to_account'] != null) e['to_account'] as String,
    };
    final current = _shown > 0 && _shown <= _edges.length ? _edges[_shown - 1] : null;

    return Column(children: [
      Expanded(
        child: FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCameraFit: CameraFit.coordinates(coordinates: _allPoints, padding: const EdgeInsets.all(48)),
            onMapReady: _fit,
          ),
          children: [
            osmTiles(),
            PolylineLayer(polylines: [
              for (final e in visible)
                Polyline(points: [_ends(e).$1, _ends(e).$2], color: _edgeColor(e['kind']), strokeWidth: 3),
            ]),
            MarkerLayer(markers: [
              // arrow + amount in the middle of each hop
              for (final e in visible) _arrow(e),
              // ATMs where cash was withdrawn
              for (final e in visible.where((e) => e['kind'] == 'ATM'))
                Marker(
                  point: _ends(e).$2,
                  width: 36,
                  height: 36,
                  child: const CircleAvatar(backgroundColor: Colors.black87, child: Icon(Icons.atm, color: Colors.white, size: 20)),
                ),
              for (final no in shownAccounts) _pin(_nodes[no]!),
            ]),
          ],
        ),
      ),
      Container(
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(children: [
          FilledButton.icon(onPressed: _play, icon: const Icon(Icons.play_arrow), label: Text(tr('Play'))),
          Expanded(
            child: Slider(
              value: _shown.toDouble(),
              max: _edges.length.toDouble(),
              divisions: max(1, _edges.length),
              label: tr('{shown} / {total} hops', {'shown': _shown, 'total': _edges.length}),
              onChanged: (v) {
                _player?.cancel();
                setState(() => _shown = v.round());
              },
            ),
          ),
          SizedBox(
            width: 220,
            child: Text(
              current == null
                  ? tr('Start: victim pays the scammer')
                  : '${formatDateTime(current['date'])}\n${rupees(current['amount'])} • ${_kindLabel(current['kind'])}'
                      '${current['location'] != null ? ' • ${current['location']['label']}' : ''}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ]),
      ),
      const _Legend(),
    ]);
  }

  Marker _arrow(Map<String, dynamic> e) {
    final (a, b) = _ends(e);
    final mid = LatLng((a.latitude + b.latitude) / 2, (a.longitude + b.longitude) / 2);
    // Screen y grows downwards while latitude grows upwards, hence the minus sign.
    final angle = atan2(-(b.latitude - a.latitude), b.longitude - a.longitude);
    return Marker(
      point: mid,
      width: 110,
      height: 46,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Transform.rotate(angle: angle, child: Icon(Icons.arrow_forward, color: _edgeColor(e['kind']), size: 22)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _edgeColor(e['kind']))),
          // white label on the (always light) map, so the text stays dark at night too
          child: Text(rupees(e['amount'], decimals: false),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
        ),
      ]),
    );
  }

  Marker _pin(Map<String, dynamic> n) {
    final color = roleColor(n['role']);
    final name = (n['business_name'] as String).isNotEmpty ? n['business_name'] : n['holder'];
    return Marker(
      point: _pos[n['account_no']]!,
      width: 130,
      height: 64,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () => showNodeDetails(context, n),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
            child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          Icon(n['role'] == 'MERCHANT' ? Icons.storefront : n['role'] == 'EXCHANGE' ? Icons.currency_bitcoin : Icons.location_on,
              color: color, size: 32),
        ]),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String t) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 14, height: 4, color: c),
            const SizedBox(width: 4),
            Text(t, style: const TextStyle(fontSize: 11)),
          ]),
        );
    // The legend sits on the page, so the swatches use night-friendly shades where needed.
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Wrap(children: [
        item(Colors.red.shade600, tr('Transfer to mule')),
        item(strong(context, Colors.green), tr('Merchant purchase')),
        item(isDark(context) ? Colors.purple.shade300 : Colors.purple, tr('To crypto exchange')),
        item(isDark(context) ? Colors.white70 : Colors.black87, tr('ATM cash')),
        item(strong(context, Colors.blue), tr('Victim pin')),
      ]),
    );
  }
}

/// Bottom sheet with everything about one account in the trail.
void showNodeDetails(BuildContext context, Map<String, dynamic> n) {
  String r(String k) => rupees(n[k] as int);
  final rows = <(String, String)>[
    (tr('Role'), roleLabel(n['role'])),
    (tr('Bank'), '${n['bank']} • ${n['branch']} (${n['ifsc']})'),
    (tr('Account'), n['account_no']),
    (tr('PAN / mobile'), '${n['pan']} • ${n['mobile']}'),
    (tr('Account status'), n['status']),
    (tr('Victim money received'), r('received')),
    if (n['forwarded'] > 0) (tr('Forwarded to others'), r('forwarded')),
    if (n['held'] > 0) (tr('Held (lien)'), r('held')),
    if (n['spent_merchant'] > 0) (tr('Spent at merchant'), r('spent_merchant')),
    if (n['cashed_out'] > 0) (tr('Withdrawn at ATM'), r('cashed_out')),
    if (n['to_crypto'] > 0) (tr('Sent to crypto exchange'), r('to_crypto')),
    if (n['crypto_frozen'] > 0) (tr('Crypto frozen at exchange'), r('crypto_frozen')),
    if (n['crypto_escaped'] > 0) (tr('Crypto sent to outside wallets'), r('crypto_escaped')),
    if (n['recovery_approved'] > 0) (tr('Court-approved recovery lien'), r('recovery_approved')),
    if (n['released'] + n['crypto_released'] > 0) (tr('Returned to victim'), rupees(n['released'] + n['crypto_released'])),
    (tr('Current balance / lien'), '${r('balance')} / ${r('lien_amount')}'),
    if (n['last_seen'] != null) (tr('Last used at'), '${n['last_seen']['label']} (${formatDateTime(n['last_seen']['date'])})'),
  ];
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(backgroundColor: roleColor(n['role']), child: const Icon(Icons.person, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(
              child: Text((n['business_name'] as String).isNotEmpty ? '${n['business_name']} (${n['holder']})' : n['holder'],
                  style: Theme.of(ctx).textTheme.titleLarge),
            ),
          ]),
          const Divider(),
          for (final (k, v) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 190, child: Text(k, style: TextStyle(color: muted(ctx)))),
                Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600))),
              ]),
            ),
        ]),
      ),
    ),
  );
}
