import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api.dart';
import 'location.dart';
import 'models.dart';

void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(error.toString()),
    backgroundColor: Colors.red.shade700,
    behavior: SnackBarBehavior.floating,
  ));
}

void showInfo(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
}

/// Forces typed letters to capitals (PAN, IFSC).
class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}

/// Coloured chip showing whether an account is active or under fraud restriction.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'ACTIVE' => ('Active', Colors.green),
      'SUSPECTED_MULE' => ('Under verification', Colors.orange),
      'CONFIRMED_MULE' => ('Blocked – fraud', Colors.red),
      _ => (status, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      // Solid light background so it reads on both white and coloured cards.
      decoration: BoxDecoration(color: Color.lerp(color, Colors.white, 0.85), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color.shade800, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

/// Asks for a 4-digit PIN. Returns null if cancelled.
Future<String?> askPin(BuildContext context, {String title = 'Enter 4-digit PIN', String? subtitle}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitle != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(subtitle)),
          TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, letterSpacing: 16),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(counterText: ''),
            onSubmitted: (v) => v.length == 4 ? Navigator.pop(ctx, v) : null,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => controller.text.length == 4 ? Navigator.pop(ctx, controller.text) : null,
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
}

/// Server address + demo location. Shared by every RakshakPay app.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.api, required this.location});
  final RakshakApi api;
  final LocationService location;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final _url = TextEditingController(text: widget.api.baseUrl);
  List<City> _cities = [];
  String? _demoCity;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _demoCity = widget.location.demoCity;
    _loadCities();
  }

  Future<void> _loadCities() async {
    try {
      final c = await widget.location.cities();
      if (mounted) setState(() => _cities = c);
    } catch (_) {}
  }

  Future<void> _test() async {
    await widget.api.setBaseUrl(_url.text);
    setState(() => _status = 'Checking…');
    try {
      await widget.api.get('/');
      setState(() => _status = '✅ Connected to RakshakPay server');
      _loadCities();
    } catch (e) {
      setState(() => _status = '❌ $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Server address', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text('The laptop running the backend, e.g. http://192.168.1.5:8000'),
          const SizedBox(height: 8),
          TextField(controller: _url, keyboardType: TextInputType.url,
              decoration: const InputDecoration(border: OutlineInputBorder())),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: _test, icon: const Icon(Icons.wifi), label: const Text('Save & test')),
          if (_status.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_status)),
          const Divider(height: 40),
          Text('Demo location', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text('Every transaction records where this phone is. In a demo all phones are in one '
              'room, so you can pretend this phone is in another city.'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            initialValue: _demoCity,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: [
              const DropdownMenuItem(value: null, child: Text('Use real GPS')),
              for (final c in _cities) DropdownMenuItem(value: c.name, child: Text('${c.name}, ${c.state}')),
            ],
            onChanged: (v) async {
              await widget.location.setDemoCity(v);
              setState(() => _demoCity = v);
            },
          ),
        ],
      ),
    );
  }
}
