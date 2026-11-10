import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'bible_api.dart';

/// Small settings and reading-state store on the phone.
class BibleStorage {
  static const _savedKey = 'saved_chapters';
  static const _legacyDarkModeKey = 'dark_mode';
  static const _themeKey = 'theme_mode';
  static const _textScaleKey = 'text_scale';
  static const _positionKey = 'reading_position';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<Set<String>> savedChapters() async => (await _prefs).getStringList(_savedKey)?.toSet() ?? {};

  Future<void> setSavedChapters(Set<String> saved) async => (await _prefs).setStringList(_savedKey, saved.toList());

  Future<void> saveChapter(String key, BibleChapter chapter) async =>
      (await _prefs).setString('chapter_$key', jsonEncode(chapter.toJson()));

  Future<BibleChapter?> chapter(String key) async {
    final data = (await _prefs).getString('chapter_$key');
    return data == null ? null : BibleChapter.fromJson(jsonDecode(data) as Map<String, dynamic>);
  }

  /// 'system', 'light' or 'dark'. Falls back to the old on/off dark mode switch.
  Future<String> themeMode() async {
    final prefs = await _prefs;
    return prefs.getString(_themeKey) ?? ((prefs.getBool(_legacyDarkModeKey) ?? false) ? 'dark' : 'system');
  }

  Future<void> setThemeMode(String value) async => (await _prefs).setString(_themeKey, value);

  Future<double> textScale() async => (await _prefs).getDouble(_textScaleKey) ?? 1.0;

  Future<void> setTextScale(double value) async => (await _prefs).setDouble(_textScaleKey, value);

  /// 'language|book|chapter', e.g. 'english|43|3'.
  Future<String?> position() async => (await _prefs).getString(_positionKey);

  Future<void> setPosition(String value) async => (await _prefs).setString(_positionKey, value);
}
