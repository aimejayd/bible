import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'bible_api.dart';

class BibleStorage {
  static const _savedKey = 'saved_chapters';
  static const _darkModeKey = 'dark_mode';

  Future<Set<String>> savedChapters() async =>
      (await SharedPreferences.getInstance()).getStringList(_savedKey)?.toSet() ?? {};

  Future<void> setSaved(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_savedKey)?.toSet() ?? {};
    value ? saved.add(key) : saved.remove(key);
    await prefs.setStringList(_savedKey, saved.toList());
  }

  Future<void> saveChapter(String key, BibleChapter chapter) async =>
      (await SharedPreferences.getInstance()).setString('chapter_$key', jsonEncode(chapter.toJson()));

  Future<BibleChapter?> chapter(String key) async {
    final data = (await SharedPreferences.getInstance()).getString('chapter_$key');
    return data == null ? null : BibleChapter.fromJson(jsonDecode(data) as Map<String, dynamic>);
  }

  Future<bool> darkMode() async =>
      (await SharedPreferences.getInstance()).getBool(_darkModeKey) ?? false;

  Future<void> setDarkMode(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_darkModeKey, value);
}
