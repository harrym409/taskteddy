import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the app-wide selected [Locale] and persists it across launches.
///
/// Singleton so any screen can read/update it. [MaterialApp] listens to this
/// via a [ListenableBuilder] and rebuilds when the language changes, so the
/// whole app re-renders immediately.
class LocaleController extends ChangeNotifier {
  static final LocaleController _instance = LocaleController._internal();
  factory LocaleController() => _instance;
  LocaleController._internal();

  static const _prefsKey = 'app_locale';

  /// Languages offered in the switcher.
  static const List<Locale> supported = [
    Locale('en'),
    Locale('hi'),
    Locale('pa'),
  ];

  Locale? _locale;

  /// null means "follow the device locale" (falls back to English if the
  /// device language is unsupported).
  Locale? get locale => _locale;

  /// Load the saved locale from disk. Call once during app startup.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefsKey);
      if (code != null && code.isNotEmpty) {
        _locale = Locale(code);
        notifyListeners();
      }
    } catch (_) {
      // Ignore storage errors — default to device locale.
    }
  }

  /// Change the active language and persist it.
  Future<void> setLocale(Locale locale) async {
    if (_locale?.languageCode == locale.languageCode) return;
    _locale = locale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, locale.languageCode);
    } catch (_) {
      // Non-fatal: the choice still applies for this session.
    }
  }
}
