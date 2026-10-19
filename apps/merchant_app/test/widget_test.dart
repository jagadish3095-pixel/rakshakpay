import 'package:flutter_test/flutter_test.dart';
import 'package:merchant_app/announcer.dart';

void main() {
  test('announcements in all three languages', () {
    expect(announcementText('en-IN', 50000), 'Received 500 rupees on RakshakPay');
    expect(announcementText('en-IN', 150050), 'Received 1500 rupees and 50 paise on RakshakPay');
    expect(announcementText('hi-IN', 50000), contains('500 रुपये'));
    expect(announcementText('kn-IN', 50000), contains('500 ರೂಪಾಯಿ'));
  });
}
