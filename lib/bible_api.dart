import 'dart:convert';
import 'dart:io';

class BibleChapter {
  const BibleChapter({
    required this.bookName,
    required this.chapter,
    required this.verses,
  });

  final String bookName;
  final int chapter;
  final List<BibleVerse> verses;

  Map<String, dynamic> toJson() => {
        'bookName': bookName,
        'chapter': chapter,
        'verses': verses
            .map((verse) => {'number': verse.number, 'text': verse.text})
            .toList(),
      };

  factory BibleChapter.fromJson(Map<String, dynamic> json) => BibleChapter(
        bookName: json['bookName'] as String,
        chapter: json['chapter'] as int,
        verses: (json['verses'] as List<dynamic>)
            .map((item) => item as Map<String, dynamic>)
            .map(
              (item) => BibleVerse(
                number: item['number'] as int,
                text: item['text'] as String,
              ),
            )
            .toList(),
      );
}

class BibleVerse {
  const BibleVerse({required this.number, required this.text});

  final int number;
  final String text;
}

/// Loads open Scripture editions from GetBible.
///
/// Kinyarwanda is intentionally not configured here: the Bible Society of
/// Rwanda edition needs an approved Digital Bible Library/API.Bible licence.
class BibleApi {
  static const _baseUrl = 'https://api.getbible.net/v3';

  Future<BibleChapter> fetchChapter({
    required String translationCode,
    required int bookNumber,
    required int chapterNumber,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(
        Uri.parse('$_baseUrl/$translationCode/$bookNumber/$chapterNumber.json'),
      );
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Bible service returned ${response.statusCode}.');
      }

      final raw = await response.transform(utf8.decoder).join();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final verses = (json['verses'] as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .map(
            (item) => BibleVerse(
              number: item['verse'] as int,
              text: (item['text'] as String).trim(),
            ),
          )
          .toList(growable: false);

      return BibleChapter(
        bookName: json['book_name'] as String,
        chapter: json['chapter'] as int,
        verses: verses,
      );
    } finally {
      client.close(force: true);
    }
  }
}
