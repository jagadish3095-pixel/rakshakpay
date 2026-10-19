/// UPI QR codes contain a link like:  upi://pay?pa=sunil6655@kaveri&pn=Sunil%20Verma&am=500.00&cu=INR
/// pa = payee address (UPI ID), pn = payee name, am = amount (optional), cu = currency.
library;

String buildUpiUri({required String vpa, required String name, int? amountPaise}) {
  final params = {
    'pa': vpa,
    'pn': name,
    if (amountPaise != null) 'am': (amountPaise / 100).toStringAsFixed(2),
    'cu': 'INR',
  };
  return Uri(scheme: 'upi', host: 'pay', queryParameters: params).toString();
}

class ScannedUpi {
  ScannedUpi(this.vpa, this.name, this.amountPaise);
  final String vpa;
  final String? name;
  final int? amountPaise;
}

/// Reads a scanned QR code. Also accepts a plain UPI ID. Returns null if it is not UPI.
ScannedUpi? parseUpiQr(String raw) {
  final text = raw.trim();
  if (RegExp(r'^[\w.\-]+@[a-z]+$', caseSensitive: false).hasMatch(text)) {
    return ScannedUpi(text.toLowerCase(), null, null);
  }
  final uri = Uri.tryParse(text);
  if (uri == null || uri.scheme.toLowerCase() != 'upi' || uri.host.toLowerCase() != 'pay') return null;
  final pa = uri.queryParameters['pa'];
  if (pa == null || pa.isEmpty) return null;
  final am = double.tryParse(uri.queryParameters['am'] ?? '');
  return ScannedUpi(pa.toLowerCase(), uri.queryParameters['pn'], am == null || am <= 0 ? null : (am * 100).round());
}
