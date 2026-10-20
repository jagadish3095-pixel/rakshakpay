import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:rakshak_core/rakshak_core.dart';

/// A payment request ("upi://pay?...") sent by another app, waiting to be shown.
/// The Home screen opens the Pay screen for it once the app is unlocked.
final pendingUpiLink = ValueNotifier<ScannedUpi?>(null);

const _channel = MethodChannel('rakshakpay/upi_link');

Future<void> initUpiLinks() async {
  _channel.setMethodCallHandler((call) async {
    if (call.method == 'onLink') _accept(call.arguments as String?);
  });
  try {
    _accept(await _channel.invokeMethod<String>('getInitialLink'));
  } on MissingPluginException {
    // Not on Android (tests): no links.
  }
}

void _accept(String? link) {
  if (link == null) return;
  final upi = parseUpiQr(link);
  if (upi != null) pendingUpiLink.value = upi;
}
