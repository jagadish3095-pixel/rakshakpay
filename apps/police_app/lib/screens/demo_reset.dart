import 'package:flutter/material.dart';
import 'package:rakshak_core/rakshak_core.dart';

import '../services.dart';

/// "Reset & load demo story": wipes the server and replays the 8-person fraud story.
/// Returns true when the story was loaded (the caller should refresh its screens).
Future<bool> resetAndLoadDemo(BuildContext context) async {
  final confirm = TextEditingController();
  var withComplaint = false;
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        icon: const Icon(Icons.restart_alt, size: 40, color: Colors.red),
        title: const Text('Reset & load demo story'),
        content: SizedBox(
          width: 480,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('This deletes EVERY account, payment and complaint on the server, then creates the '
                '8-person story: Priya is scammed of ₹50,000 and the money moves through 7 mules, a phone shop '
                'and a crypto exchange.\n\nEveryone on every phone will have to log in again.'),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: withComplaint,
              onChanged: (v) => setState(() => withComplaint = v!),
              title: const Text("Also file Priya's complaint now"),
              subtitle: const Text('Leave off to file it live from her phone during the demo'),
            ),
            TextField(
              controller: confirm,
              decoration: const InputDecoration(labelText: 'Type RESET to confirm'),
              onChanged: (_) => setState(() {}),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: confirm.text.trim().toUpperCase() == 'RESET' ? () => Navigator.pop(ctx, true) : null,
            child: const Text('Reset & load'),
          ),
        ],
      ),
    ),
  );
  if (go != true || !context.mounted) return false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AlertDialog(
      content: Row(children: [
        CircularProgressIndicator(),
        SizedBox(width: 16),
        Expanded(child: Text('Resetting and playing the story…\nThis can take up to a minute.')),
      ]),
    ),
  );
  try {
    final story = await api.post('/api/demo/load-story?file_complaint=$withComplaint');
    await api.setToken(story['police_token']);
    live.stop();
    live.start();
    if (!context.mounted) return true;
    Navigator.pop(context); // progress dialog
    await _showLogins(context, story);
    return true;
  } catch (e) {
    if (context.mounted) {
      Navigator.pop(context);
      showError(context, e);
    }
    return false;
  }
}

Future<void> _showLogins(BuildContext context, Map<String, dynamic> story) {
  final logins = story['logins'] as Map<String, dynamic>;
  const roles = {
    'victim': 'Victim', 'p1': 'Scammer (P1)', 'p3': 'Mule P3', 'p4': 'Mule P4', 'p5': 'Mule P5',
    'p6': 'Mule P6', 'p7': 'Mule P7 (crypto)', 'p8': 'Mule P8 (bought phone)', 'shop': 'Phone shop',
  };
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Demo story loaded'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (story['complaint'] != null)
              Text('Complaint ${story['complaint']['ack_no']} filed: ${rupees(story['complaint']['held'])} on hold.\n')
            else
              const Text('Next: on a phone, log in to RakshakPay as Priya (9000000002) and report the ₹50,000 '
                  'payment to Pankaj.\n'),
            Text('Bank password ${logins['bank_password']} • MPIN ${logins['mpin']} • ATM PIN ${logins['atm_pin']}\n'
                'RakshakPay passcode ${logins['rakshakpay_passcode']} • UPI PIN ${logins['upi_pin']} • '
                'CoinVault PIN ${logins['coinvault_pin']}\n'),
            for (final p in story['people'])
              Text('${roles[p['role']] ?? p['role']}: ${p['name']} • ${p['bank']} • mobile ${p['mobile']} • ${p['city']}',
                  style: const TextStyle(fontSize: 13)),
          ]),
        ),
      ),
      actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
    ),
  );
}
