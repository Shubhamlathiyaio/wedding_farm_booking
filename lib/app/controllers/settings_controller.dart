import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SettingsController extends GetxController {
  static SettingsController get to => Get.find();

  final _box = GetStorage();

  // Keys
  static const _kTheme = 'theme_mode';
  static const _kLang = 'language_code';

  // Rx state — default to light mode
  final themeMode = ThemeMode.light.obs;
  final locale = const Locale('en', 'US').obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  void _loadSettings() {
    final storedTheme = _box.read<String>(_kTheme) ?? 'light';
    themeMode.value = _parseThemeMode(storedTheme);

    final storedLang = _box.read<String>(_kLang) ?? 'en';
    locale.value = _parseLocale(storedLang);
  }

  // ─── Theme ───────────────────────────────────────────────────────────────

  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    _box.write(_kTheme, _themeModeKey(mode));
    Get.changeThemeMode(mode);
  }

  ThemeMode _parseThemeMode(String key) {
    switch (key) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  String _themeModeKey(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
      default:
        return 'light';
    }
  }

  bool get isLight => themeMode.value == ThemeMode.light;
  bool get isDark => themeMode.value == ThemeMode.dark;

  // ─── Language ────────────────────────────────────────────────────────────

  void setLocale(String languageCode) {
    locale.value = _parseLocale(languageCode);
    _box.write(_kLang, languageCode);
    Get.updateLocale(locale.value);
  }

  Locale _parseLocale(String code) {
    switch (code) {
      case 'gu':
        return const Locale('gu', 'IN');
      case 'hi':
        return const Locale('hi', 'IN');
      default:
        return const Locale('en', 'US');
    }
  }

  String get currentLanguageCode => locale.value.languageCode;

  List<Map<String, String>> get supportedLanguages => [
        {'code': 'en', 'name': 'English', 'native': 'English'},
        {'code': 'gu', 'name': 'Gujarati', 'native': 'ગુજરાતી'},
        {'code': 'hi', 'name': 'Hindi', 'native': 'हिंदी'},
      ];
}
