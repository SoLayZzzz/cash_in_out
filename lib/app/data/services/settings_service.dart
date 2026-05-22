import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class SettingsService {
  static const _kLocaleKey = 'settings.locale_code_v1'; // 'en' | 'km'
  static const _kThemeKey = 'settings.theme_mode_v1'; // 'system' | 'light' | 'dark'

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<Locale?> getSavedLocale() async {
    final p = await _prefs;
    final code = p.getString(_kLocaleKey);
    if (code == null) return null;
    return Locale(code);
  }

  Future<void> saveLocale(Locale locale) async {
    final p = await _prefs;
    await p.setString(_kLocaleKey, locale.languageCode);
  }

  Future<ThemeMode?> getSavedThemeMode() async {
    final p = await _prefs;
    final mode = p.getString(_kThemeKey);
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return null;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final p = await _prefs;
    final value = switch (mode) { ThemeMode.dark => 'dark', ThemeMode.light => 'light', _ => 'system' };
    await p.setString(_kThemeKey, value);
  }
}
