import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api.dart';
import 'app_settings.dart';
import 'location.dart';

/// Translates an error or server message for display. Form errors from the server look like
/// "Mobile: Enter a valid 10-digit Indian mobile number"; when the whole text has no translation,
/// the parts before and after the first ": " are translated separately.
String trMessage(Object message) {
  final text = message.toString();
  final whole = tr(text);
  if (whole != text) return whole;
  final i = text.indexOf(': ');
  if (i <= 0) return whole;
  return '${tr(text.substring(0, i))}: ${tr(text.substring(i + 2))}';
}

/// Shows an error in a red bar. For an [ApiException] the text is the server's `detail`
/// message; it is translated when the translation tables know it (already translated text
/// passed by an app does not match any key and is shown as it is).
void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(trMessage(error)),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void showInfo(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(message)), behavior: SnackBarBehavior.floating));
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
      'ACTIVE' => (tr('Active'), Colors.green),
      'SUSPECTED_MULE' => (tr('Under verification'), Colors.orange),
      'CONFIRMED_MULE' => (tr('Blocked – fraud'), Colors.red),
      _ => (status, Colors.grey),
    };
    final dark = isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      // Solid (opaque) background so it reads on both plain and coloured cards; a dark tint at night.
      decoration: BoxDecoration(color: chipBg(context, color), borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(color: dark ? color.shade200 : color.shade800, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

/// Asks for a 4-digit PIN. Returns null if cancelled.
/// [title] defaults to "Enter 4-digit PIN"; [title] and [subtitle] are translated when possible.
Future<String?> askPin(BuildContext context, {String? title, String? subtitle}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(tr(title ?? 'Enter 4-digit PIN')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitle != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(tr(subtitle))),
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
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Cancel'))),
        FilledButton(
          onPressed: () => controller.text.length == 4 ? Navigator.pop(ctx, controller.text) : null,
          child: Text(tr('Confirm')),
        ),
      ],
    ),
  );
}

/// Night mode, language, location permission and server address. Shared by every RakshakPay app.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.api, required this.location, this.makesPayments = true});
  final RakshakApi api;
  final LocationService location;

  /// Shows the location section (location is mandatory for payments). Off for apps that never pay.
  final bool makesPayments;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  late final _url = TextEditingController(text: widget.api.baseUrl);
  String _status = '';
  GpsProblem? _gps;
  bool _gpsChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.makesPayments) _checkGps();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Coming back from Android's settings: show the new permission state.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.makesPayments) _checkGps();
  }

  Future<void> _checkGps() async {
    final p = await widget.location.check();
    if (!mounted) return;
    setState(() {
      _gps = p;
      _gpsChecked = true;
    });
  }

  Future<void> _test() async {
    await widget.api.setBaseUrl(_url.text);
    setState(() => _status = tr('Checking…'));
    try {
      await widget.api.get('/');
      setState(() => _status = '✅ ${tr('Connected to RakshakPay server')}');
    } catch (e) {
      setState(() => _status = '❌ ${trMessage(e)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final heading = Theme.of(context).textTheme.titleMedium;
    return ListenableBuilder(
      listenable: appSettings,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(tr('Settings'))),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(tr('Night mode'), style: heading),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: const Icon(Icons.brightness_auto),
                  label: Text(tr('Auto')),
                ),
                ButtonSegment(value: ThemeMode.light, icon: const Icon(Icons.light_mode), label: Text(tr('Day'))),
                ButtonSegment(value: ThemeMode.dark, icon: const Icon(Icons.dark_mode), label: Text(tr('Night'))),
              ],
              selected: {appSettings.themeMode},
              onSelectionChanged: (s) => appSettings.setThemeMode(s.first),
            ),
            const SizedBox(height: 4),
            Text(tr("Auto follows the phone's dark theme setting."), style: TextStyle(color: muted(context))),
            const Divider(height: 40),
            Text(tr('Language'), style: heading),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [for (final e in kLanguages.entries) ButtonSegment(value: e.key, label: Text(e.value))],
              selected: {appSettings.language},
              onSelectionChanged: (s) => appSettings.setLanguage(s.first),
            ),
            if (widget.makesPayments) ...[
              const Divider(height: 40),
              Text(tr('Location'), style: heading),
              const SizedBox(height: 4),
              Text(
                tr(
                  'Location is mandatory for payments. Every payment records where the phone was, so that '
                  'money stolen by fraudsters can be traced.',
                ),
              ),
              const SizedBox(height: 8),
              if (_gpsChecked)
                Card(
                  color: _gps == null ? softBg(context, Colors.green) : softBg(context, Colors.red),
                  child: ListTile(
                    leading: Icon(
                      _gps == null ? Icons.location_on : Icons.location_off,
                      color: strong(context, _gps == null ? Colors.green : Colors.red),
                    ),
                    title: Text(switch (_gps) {
                      null => tr('Location allowed'),
                      GpsProblem.serviceOff => tr('Location (GPS) is turned off'),
                      GpsProblem.denied || GpsProblem.deniedForever => tr('Location permission not given'),
                      GpsProblem.failed => tr('Location not available'),
                    }),
                    trailing: _gps == null
                        ? null
                        : FilledButton(
                            onPressed: () async {
                              await widget.location.askPermission();
                              _checkGps();
                            },
                            child: Text(tr('Allow')),
                          ),
                  ),
                ),
            ],
            const Divider(height: 40),
            Text(tr('Server address'), style: heading),
            const SizedBox(height: 4),
            Text(tr('The computer running the RakshakPay server, e.g. https://rakshakpay.onrender.com')),
            const SizedBox(height: 8),
            TextField(
              controller: _url,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(onPressed: _test, icon: const Icon(Icons.wifi), label: Text(tr('Save & test'))),
            if (_status.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_status)),
          ],
        ),
      ),
    );
  }
}
