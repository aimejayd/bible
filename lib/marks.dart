import 'dart:convert';

import 'package:flutter/material.dart';

/// Highlight colours a reader can give a verse.
enum HighlightColor {
  yellow(Color(0xFFFFE66D), 'Yellow'),
  green(Color(0xFFA8E6A1), 'Green'),
  blue(Color(0xFFA3D5FF), 'Blue'),
  pink(Color(0xFFFFB8D1), 'Pink'),
  orange(Color(0xFFFFC98B), 'Orange');

  const HighlightColor(this.color, this.label);
  final Color color;
  final String label;

  /// Softer version for dark mode.
  Color get dim => color.withValues(alpha: .38);
}

/// A highlight and/or note on one verse. Keyed by book, chapter and verse,
/// so it shows in every language.
class VerseMark {
  const VerseMark({required this.book, required this.chapter, required this.verse, this.color, this.note, required this.updated});

  final int book, chapter, verse;
  final HighlightColor? color;
  final String? note;
  final DateTime updated;

  String get key => keyFor(book, chapter, verse);
  static String keyFor(int book, int chapter, int verse) => '${book}_${chapter}_$verse';

  bool get isEmpty => color == null && (note == null || note!.trim().isEmpty);

  VerseMark copyWith({HighlightColor? color, bool clearColor = false, String? note, bool clearNote = false}) => VerseMark(
        book: book,
        chapter: chapter,
        verse: verse,
        color: clearColor ? null : (color ?? this.color),
        note: clearNote ? null : (note ?? this.note),
        updated: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'b': book,
        'c': chapter,
        'v': verse,
        if (color != null) 'color': color!.name,
        if (note != null) 'note': note,
        'updated': updated.millisecondsSinceEpoch,
      };

  static VerseMark? fromJson(Map<String, dynamic> json) {
    final colorName = json['color'] as String?;
    final colors = HighlightColor.values.where((c) => c.name == colorName);
    return VerseMark(
      book: json['b'] as int,
      chapter: json['c'] as int,
      verse: json['v'] as int,
      color: colors.isEmpty ? null : colors.first,
      note: json['note'] as String?,
      updated: DateTime.fromMillisecondsSinceEpoch(json['updated'] as int? ?? 0),
    );
  }

  static String encodeAll(Map<String, VerseMark> marks) => jsonEncode(marks.values.map((m) => m.toJson()).toList());

  static Map<String, VerseMark> decodeAll(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final out = <String, VerseMark>{};
      for (final item in list) {
        final mark = fromJson(item as Map<String, dynamic>);
        if (mark != null) out[mark.key] = mark;
      }
      return out;
    } catch (_) {
      return {};
    }
  }
}
