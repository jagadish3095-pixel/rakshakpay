import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n_core.dart';

/// Languages offered in Settings (code -> name written in that language).
const kLanguages = {'en': 'English', 'hi': 'हिन्दी', 'kn': 'ಕನ್ನಡ'};

const kSupportedLocales = [Locale('en', 'IN'), Locale('hi', 'IN'), Locale('kn', 'IN')];
const kLocalizationsDelegates = GlobalMaterialLocalizations.delegates;

/// Night mode and language, saved on the phone. Every app's MaterialApp listens to it.
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final instance = AppSettings._();

  static const _themeKey = 'app.theme';
  static const _languageKey = 'app.language';

  SharedPreferences? _prefs;
  ThemeMode themeMode = ThemeMode.system;
  String language = 'en';

  Locale get locale => kSupportedLocales.firstWhere((l) => l.languageCode == language);

  /// Call once in main(), before runApp. [defaultTheme] is used until the user picks one.
  Future<void> init({ThemeMode defaultTheme = ThemeMode.system}) async {
    _prefs = await SharedPreferences.getInstance();
    themeMode = ThemeMode.values.asNameMap()[_prefs!.getString(_themeKey)] ?? defaultTheme;
    final saved = _prefs!.getString(_languageKey);
    language = kLanguages.containsKey(saved) ? saved! : 'en';
    addTranslations(coreTranslations);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    await _prefs?.setString(_themeKey, mode.name);
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (!kLanguages.containsKey(code)) return;
    language = code;
    await _prefs?.setString(_languageKey, code);
    notifyListeners();
    // Text built with tr() does not depend on any InheritedWidget, so rebuild every screen,
    // including the ones underneath the current one.
    WidgetsBinding.instance.addPostFrameCallback((_) => _rebuildAll());
  }

  static void _rebuildAll() {
    void rebuild(Element e) {
      e.markNeedsBuild();
      e.visitChildren(rebuild);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(rebuild);
  }
}

final appSettings = AppSettings.instance;

final Map<String, Map<String, String>> _tables = {'hi': {}, 'kn': {}};

/// Adds an app's translations: {'hi': {English: Hindi}, 'kn': {English: Kannada}}.
void addTranslations(Map<String, Map<String, String>> tables) {
  tables.forEach((lang, table) => _tables.putIfAbsent(lang, () => {}).addAll(table));
}

/// Translates English text into the chosen language. Untranslated text stays in English.
/// Values in [args] fill {placeholders}: tr('Pay {amount}', {'amount': rupees(x)}).
String tr(String english, [Map<String, Object?>? args]) {
  var text = appSettings.language == 'en' ? english : (_tables[appSettings.language]?[english] ?? english);
  args?.forEach((key, value) => text = text.replaceAll('{$key}', '$value'));
  return text;
}

// ---------------------------------------------------------------- colours that work at night

bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

/// Pale background for a highlighted card (e.g. red.shade50); a dark tint at night.
Color softBg(BuildContext context, MaterialColor color) => isDark(context)
    ? Color.alphaBlend(color.withValues(alpha: 0.20), Theme.of(context).colorScheme.surface)
    : color.shade50;

/// Background for a small coloured chip (e.g. green.shade100); a darker tint at night.
Color chipBg(BuildContext context, MaterialColor color) => isDark(context)
    ? Color.alphaBlend(color.withValues(alpha: 0.35), Theme.of(context).colorScheme.surface)
    : color.shade100;

/// Coloured text or icon (e.g. green.shade700); a lighter shade at night so it stays readable.
Color strong(BuildContext context, MaterialColor color) => isDark(context) ? color.shade300 : color.shade700;

/// Grey secondary text (instead of Colors.black54 / grey.shade700).
Color muted(BuildContext context) => Theme.of(context).colorScheme.onSurfaceVariant;

/// Light grey panel (instead of Colors.grey.shade100).
Color panelBg(BuildContext context) => Theme.of(context).colorScheme.surfaceContainerHighest;
