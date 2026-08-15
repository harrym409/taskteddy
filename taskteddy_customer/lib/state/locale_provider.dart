import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted app locale. `null` means "follow the system language".
///
/// The saved language code is loaded from [SharedPreferences] on first build
/// and re-persisted whenever it changes, so the choice survives restarts.
class LocaleNotifier extends Notifier<Locale?> {
  static const _prefsKey = 'app_locale_code';

  /// Language codes the app ships translations for.
  static const supportedCodes = {'en', 'hi', 'pa'};

  @override
  Locale? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null && supportedCodes.contains(code)) {
      state = Locale(code);
    }
  }

  /// Sets the active locale (or `null` to follow the system) and persists it.
  Future<void> setLocale(Locale? locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, locale.languageCode);
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
  name: 'localeProvider',
);
