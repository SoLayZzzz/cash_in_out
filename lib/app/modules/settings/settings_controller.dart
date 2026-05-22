import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/translations/app_translations.dart';
import '../../data/services/settings_service.dart';

class SettingsController extends GetxService {
  final SettingsService _service = SettingsService();

  final Rx<Locale> locale = AppTranslations.en.obs;
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  Future<SettingsController> init() async {
    // Initialize locale from saved, device, or default
    final savedLocale = await _service.getSavedLocale();
    if (savedLocale != null) {
      setLocale(savedLocale, persist: false);
    } else {
      final dev = Get.deviceLocale;
      if (dev != null && (dev.languageCode == 'en' || dev.languageCode == 'km')) {
        setLocale(Locale(dev.languageCode), persist: false);
      } else {
        setLocale(AppTranslations.en, persist: false);
      }
    }

    // Initialize theme
    final savedTheme = await _service.getSavedThemeMode();
    setThemeMode(savedTheme ?? ThemeMode.system, persist: false);

    return this;
  }

  Future<void> setLocale(Locale value, {bool persist = true}) async {
    locale.value = value;
    Get.updateLocale(value);
    if (persist) await _service.saveLocale(value);
  }

  Future<void> setThemeMode(ThemeMode value, {bool persist = true}) async {
    themeMode.value = value;
    Get.changeThemeMode(value);
    if (persist) await _service.saveThemeMode(value);
  }
}
