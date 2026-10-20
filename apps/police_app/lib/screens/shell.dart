import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';
import 'complaints_screen.dart';
import 'court_orders_screen.dart';
import 'dashboard_screen.dart';
import 'demo_reset.dart';
import 'login_screen.dart';
import 'mules_screen.dart';
import 'verifications_screen.dart';

/// Main navigation: side rail on laptops/tablets, bottom bar on phones.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;
  int _generation = 0; // bumped after a demo reset so every screen reloads

  static const _destinations = [
    (Icons.dashboard, 'Dashboard'),
    (Icons.assignment, 'Complaints'),
    (Icons.gavel, 'Court orders'),
    (Icons.fact_check, 'Verifications'),
    (Icons.gpp_bad, 'Mule list'),
  ];

  Future<void> _logout() async {
    live.stop();
    await api.setToken(null);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final page = KeyedSubtree(
      key: ValueKey('$_tab-$_generation'),
      child: switch (_tab) {
        0 => const DashboardScreen(),
        1 => const PoliceComplaintsScreen(),
        2 => const CourtOrdersScreen(),
        3 => const VerificationsScreen(),
        _ => const MulesScreen(),
      },
    );
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [Icon(Icons.local_police), SizedBox(width: 8), Text('Cyber Police')]),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: kAmber),
            onPressed: () async {
              if (await resetAndLoadDemo(context)) {
                setState(() {
                  _tab = 0;
                  _generation++;
                });
              }
            },
            icon: const Icon(Icons.restart_alt),
            label: Text(MediaQuery.sizeOf(context).width >= 600 ? 'Demo reset' : ''),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => SettingsScreen(api: api, location: location))),
          ),
          IconButton(tooltip: 'Log out', icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: wide
          ? Row(children: [
              NavigationRail(
                selectedIndex: _tab,
                labelType: NavigationRailLabelType.all,
                onDestinationSelected: (i) => setState(() => _tab = i),
                destinations: [
                  for (final (icon, label) in _destinations)
                    NavigationRailDestination(icon: Icon(icon), label: Text(label)),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: page),
            ])
          : page,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: [
                for (final (icon, label) in _destinations) NavigationDestination(icon: Icon(icon), label: label),
              ],
            ),
    );
  }
}
