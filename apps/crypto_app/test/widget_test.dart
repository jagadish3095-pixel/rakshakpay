import 'package:crypto_app/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('coin quantities use 8 decimal places', () {
    expect(formatQty(100000000), '1');
    expect(formatQty(12345678), '0.12345678');
    expect(formatQty(50000), '0.0005');
    expect(parseQty('0.0005'), 50000);
    expect(parseQty('abc'), isNull);
    expect(parseQty('0'), isNull);
  });
}
