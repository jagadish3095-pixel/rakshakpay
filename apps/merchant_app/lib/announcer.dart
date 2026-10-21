import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Languages the soundbox can speak. Code = Android text-to-speech locale.
const kVoiceLanguages = {'en-IN': 'English', 'hi-IN': 'हिन्दी (Hindi)', 'kn-IN': 'ಕನ್ನಡ (Kannada)'};

/// What the soundbox says for a payment, e.g. "Received 1500 rupees on RakshakPay".
String announcementText(String lang, int paise) {
  final rupees = paise ~/ 100, p = paise % 100;
  switch (lang) {
    case 'hi-IN':
      final amt = p == 0 ? '$rupees रुपये' : '$rupees रुपये $p पैसे';
      return 'रक्षकपे पर $amt प्राप्त हुए';
    case 'kn-IN':
      final amt = p == 0 ? '$rupees ರೂಪಾಯಿ' : '$rupees ರೂಪಾಯಿ $p ಪೈಸೆ';
      return 'ರಕ್ಷಕ್‌ಪೇ ನಲ್ಲಿ $amt ಸ್ವೀಕರಿಸಲಾಗಿದೆ';
    default:
      final amt = p == 0 ? '$rupees rupees' : '$rupees rupees and $p paise';
      return 'Received $amt on RakshakPay';
  }
}

/// Speaks payments one after another using the phone's text-to-speech.
class Announcer {
  final _tts = FlutterTts();
  late SharedPreferences _prefs;
  final _queue = <String>[];
  bool _speaking = false;

  String get language => _prefs.getString('merchant.lang') ?? 'en-IN';
  bool get enabled => _prefs.getBool('merchant.sound') ?? true;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _tts.awaitSpeakCompletion(true);
    await _tts.setSpeechRate(0.45);
    await _applyLanguage();
  }

  Future<void> setLanguage(String lang) async {
    await _prefs.setString('merchant.lang', lang);
    await _applyLanguage();
  }

  Future<void> setEnabled(bool on) => _prefs.setBool('merchant.sound', on);

  /// Some phones have no Hindi/Kannada voice installed; fall back to English then.
  Future<bool> languageAvailable(String lang) async => (await _tts.isLanguageAvailable(lang)) == true;

  Future<void> _applyLanguage() async {
    final lang = await languageAvailable(language) ? language : 'en-IN';
    await _tts.setLanguage(lang);
  }

  Future<void> paymentReceived(int paise) async {
    if (!enabled) return;
    final lang = await languageAvailable(language) ? language : 'en-IN';
    _queue.add(announcementText(lang, paise));
    if (_speaking) return;
    _speaking = true;
    while (_queue.isNotEmpty) {
      await _tts.speak(_queue.removeAt(0));
    }
    _speaking = false;
  }

  Future<void> test() async {
    final was = enabled;
    await setEnabled(true);
    await paymentReceived(50000);
    await setEnabled(was);
  }
}
