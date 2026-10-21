import 'package:flutter_test/flutter_test.dart';
import 'package:police_app/widgets/trail_map.dart';

void main() {
  test('accounts are placed where they forwarded the money from', () {
    final detail = {
      'nodes': [
        {'account_no': 'V', 'role': 'VICTIM', 'home': {'lat': 12.9, 'lng': 77.5}, 'last_seen': null},
        {'account_no': 'M', 'role': 'MULE', 'home': {'lat': 22.5, 'lng': 88.3}, 'last_seen': null},
        {'account_no': 'S', 'role': 'MERCHANT', 'home': {'lat': 26.9, 'lng': 75.8}, 'last_seen': null},
      ],
      'edges': [
        {'from_account': 'V', 'to_account': 'M', 'kind': 'TRANSFER', 'location': {'lat': 13.0, 'lng': 77.6}},
        {'from_account': 'M', 'to_account': 'S', 'kind': 'MERCHANT', 'location': {'lat': 23.9, 'lng': 86.8}},
      ],
    };
    final pos = nodePositions(detail);
    expect(pos['V']!.latitude, 13.0); // victim's phone location at payment time
    expect(pos['M']!.latitude, 23.9); // mule's location when forwarding (not home branch)
    expect(pos['S']!.latitude, 23.9); // shop: where the buyer's phone was when paying it
  });
}
