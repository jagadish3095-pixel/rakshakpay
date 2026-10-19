import 'package:intl/intl.dart';

final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
final _inrWhole = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

/// 1234500 paise -> "₹12,345.00" (Indian digit grouping: ₹1,00,000).
String rupees(int paise, {bool decimals = true}) {
  final value = paise / 100;
  return (decimals ? _inr : _inrWhole).format(value);
}

/// "12,345.50" -> 1234550 paise. Returns null if the text is not a valid amount.
int? parsePaise(String text) {
  final clean = text.replaceAll(',', '').replaceAll('₹', '').trim();
  final value = double.tryParse(clean);
  if (value == null || value <= 0) return null;
  return (value * 100).round();
}

final _dateTime = DateFormat('dd MMM yyyy, hh:mm a');
final _date = DateFormat('dd-MM-yyyy');

String formatDateTime(String iso) => _dateTime.format(DateTime.parse(iso));
String formatDate(String iso) => _date.format(DateTime.parse(iso));
