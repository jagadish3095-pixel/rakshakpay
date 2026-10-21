import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';
import '../widgets/trail_map.dart' show osmTiles;
import 'complaints_screen.dart';

/// Overview for the cyber cell: totals, hotspot map, latest complaints.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with LiveRefresh {
  Map<String, dynamic>? _d;

  @override
  void initState() {
    super.initState();
    reload();
    startLive();
  }

  @override
  Future<void> reload() async {
    try {
      final d = await api.get('/api/police/dashboard');
      if (mounted) setState(() => _d = d);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    if (d == null) return const Center(child: CircularProgressIndicator());
    String r(String k) => rupees(d[k] as int, decimals: false);
    final hotspots = (d['hotspots'] as List).cast<Map<String, dynamic>>();
    final recent = (d['recent'] as List).cast<Map<String, dynamic>>();
    final wide = MediaQuery.sizeOf(context).width >= 1100;

    final stats = Wrap(spacing: 8, runSpacing: 8, children: [
      StatTile(tr('Complaints'), '${d['complaints']}', icon: Icons.assignment),
      StatTile(tr('Reported loss'), r('reported_amount'), color: strong(context, Colors.red), icon: Icons.report),
      StatTile(tr('Held (liens)'), r('held'), color: strong(context, Colors.orange), icon: Icons.lock),
      StatTile(tr('Crypto frozen'), r('crypto_frozen'), color: strong(context, Colors.purple), icon: Icons.ac_unit),
      StatTile(tr('Returned to victims'), r('recovered'), color: strong(context, Colors.green), icon: Icons.savings),
      StatTile(tr('Mule accounts'), '${d['mule_accounts']}', color: strong(context, Colors.red), icon: Icons.gpp_bad),
      StatTile(tr('Court orders pending'), '${d['court_pending']}', color: strong(context, Colors.brown), icon: Icons.gavel),
    ]);

    final map = Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(height: wide ? 520 : 360, child: _HotspotMap(hotspots)),
    );

    final hotspotList = Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(tr('Mule hotspots'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        if (hotspots.isEmpty) Padding(padding: const EdgeInsets.all(16), child: Text(tr('No data yet'))),
        for (final h in hotspots.take(8))
          ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: chipBg(context, Colors.red),
              child: Text('${h['mules'] + h['cashouts']}', style: const TextStyle(fontSize: 12)),
            ),
            title: Text('${h['city']}, ${h['state']}'),
            subtitle: Text(tr('{mules} mules • {cashouts} ATM cash-outs • {amount} victim money',
                {'mules': h['mules'], 'cashouts': h['cashouts'], 'amount': rupees(h['amount'], decimals: false)})),
          ),
      ]),
    );

    final recentList = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(tr('Latest complaints'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      if (recent.isEmpty) Padding(padding: const EdgeInsets.all(16), child: Text(tr('No complaints yet'))),
      for (final c in recent) ComplaintTile(c),
    ]);

    return RefreshIndicator(
      onRefresh: reload,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          const Icon(Icons.circle, size: 10, color: Colors.green),
          const SizedBox(width: 6),
          Text(tr('Live')),
          const Spacer(),
          IconButton(tooltip: tr('Refresh'), onPressed: reload, icon: const Icon(Icons.refresh)),
        ]),
        stats,
        const SizedBox(height: 12),
        if (wide)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 3, child: map),
            Expanded(flex: 2, child: hotspotList),
          ])
        else ...[
          map,
          hotspotList,
        ],
        const SizedBox(height: 12),
        recentList,
      ]),
    );
  }
}

class _HotspotMap extends StatelessWidget {
  const _HotspotMap(this.hotspots);
  final List<Map<String, dynamic>> hotspots;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: const MapOptions(initialCenter: LatLng(22.5, 80.0), initialZoom: 4.4),
      children: [
        osmTiles(),
        CircleLayer(circles: [
          for (final h in hotspots)
            CircleMarker(
              point: LatLng((h['lat'] as num).toDouble(), (h['lng'] as num).toDouble()),
              radius: 10 + 6 * sqrt((h['mules'] as int) + (h['cashouts'] as int)).toDouble(),
              color: Colors.red.withValues(alpha: 0.35),
              borderColor: Colors.red.shade800,
              borderStrokeWidth: 2,
            ),
        ]),
        MarkerLayer(markers: [
          for (final h in hotspots)
            Marker(
              point: LatLng((h['lat'] as num).toDouble(), (h['lng'] as num).toDouble()),
              width: 120,
              height: 20,
              alignment: Alignment.bottomCenter,
              child: Text('${h['city']} (${h['mules'] + h['cashouts']})', textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
            ),
        ]),
      ],
    );
  }
}
