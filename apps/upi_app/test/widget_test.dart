import 'package:flutter_test/flutter_test.dart';
import 'package:upi_app/upi_uri.dart';

void main() {
  test('QR link round-trips UPI ID, name and amount', () {
    final uri = buildUpiUri(vpa: 'lakshmimobiles@narmada', name: 'Lakshmi Mobiles', amountPaise: 1500000);
    expect(uri, startsWith('upi://pay?'));
    final scanned = parseUpiQr(uri)!;
    expect(scanned.vpa, 'lakshmimobiles@narmada');
    expect(scanned.name, 'Lakshmi Mobiles');
    expect(scanned.amountPaise, 1500000);
  });

  test('reads real-world UPI QR formats', () {
    final s = parseUpiQr('upi://pay?pa=Ravi6780@ganga&pn=Ravi%20Kumar&cu=INR')!;
    expect(s.vpa, 'ravi6780@ganga');
    expect(s.amountPaise, isNull);
    expect(parseUpiQr('sunil6655@kaveri')!.vpa, 'sunil6655@kaveri');
  });

  test('ignores non-UPI codes', () {
    expect(parseUpiQr('https://example.com'), isNull);
    expect(parseUpiQr('upi://pay?pn=NoAddress'), isNull);
  });
}
