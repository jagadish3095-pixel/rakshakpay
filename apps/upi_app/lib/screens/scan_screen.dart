import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rakshak_core/rakshak_core.dart';

import 'pay_screen.dart';

/// Camera QR scanner. Any standard UPI QR (upi://pay?...) works.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, required this.profile});
  final UpiProfile profile;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final raw = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
    if (raw == null) return;
    final upi = parseUpiQr(raw);
    if (upi == null) {
      showError(context, tr('This QR code is not a UPI payment code'));
      return;
    }
    _handled = true;
    Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => PayScreen(profile: widget.profile, to: upi.vpa, amountPaise: upi.amountPaise)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(tr('Scan any UPI QR')),
        actions: [
          IconButton(
            tooltip: tr('Torch'),
            icon: const Icon(Icons.flashlight_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                  tr('Camera not available: {error}.\n'
                      'Allow camera permission in phone Settings, or pay by UPI ID instead.',
                      {'error': error.errorCode.name}),
                  textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
            ),
          ),
        ),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 32,
          child: FilledButton.tonalIcon(
            onPressed: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => PayScreen(profile: widget.profile))),
            icon: const Icon(Icons.keyboard),
            label: Text(tr('Enter UPI ID or mobile instead')),
          ),
        ),
      ]),
    );
  }
}
