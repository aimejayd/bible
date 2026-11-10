import 'bible_catalog.dart';

enum BibleLanguage { english, french, kinyarwanda }

extension BibleLanguageDetails on BibleLanguage {
  String get label => switch (this) {
        BibleLanguage.english => 'English',
        BibleLanguage.french => 'Français',
        BibleLanguage.kinyarwanda => 'Kinyarwanda',
      };

  String get short => switch (this) {
        BibleLanguage.english => 'EN',
        BibleLanguage.french => 'FR',
        BibleLanguage.kinyarwanda => 'RW',
      };

  String get edition => switch (this) {
        BibleLanguage.english => 'World English Bible',
        BibleLanguage.french => 'Bible Darby',
        BibleLanguage.kinyarwanda => 'Bibiliya Yera',
      };

  /// Bundled edition folder in assets/bibles, or null when the text is not licensed yet.
  String? get code => switch (this) {
        BibleLanguage.english => 'web',
        BibleLanguage.french => 'darby',
        BibleLanguage.kinyarwanda => null,
      };

  String bookName(BibleBook book) => switch (this) {
        BibleLanguage.english => book.name,
        BibleLanguage.french => frenchBookNames[book.number - 1],
        BibleLanguage.kinyarwanda => kinyarwandaBookNames[book.number - 1],
      };

  int chapterCount(BibleBook book) =>
      this == BibleLanguage.french ? frenchChapterCounts[book.number] ?? book.chapters : book.chapters;
}
