class BibleBook {
  const BibleBook({
    required this.number,
    required this.name,
    required this.chapters,
  });

  final int number;
  final String name;
  final int chapters;
}

const bibleBooks = [
  BibleBook(number: 1, name: 'Genesis', chapters: 50), BibleBook(number: 2, name: 'Exodus', chapters: 40), BibleBook(number: 3, name: 'Leviticus', chapters: 27), BibleBook(number: 4, name: 'Numbers', chapters: 36), BibleBook(number: 5, name: 'Deuteronomy', chapters: 34), BibleBook(number: 6, name: 'Joshua', chapters: 24), BibleBook(number: 7, name: 'Judges', chapters: 21), BibleBook(number: 8, name: 'Ruth', chapters: 4), BibleBook(number: 9, name: '1 Samuel', chapters: 31), BibleBook(number: 10, name: '2 Samuel', chapters: 24), BibleBook(number: 11, name: '1 Kings', chapters: 22), BibleBook(number: 12, name: '2 Kings', chapters: 25), BibleBook(number: 13, name: '1 Chronicles', chapters: 29), BibleBook(number: 14, name: '2 Chronicles', chapters: 36), BibleBook(number: 15, name: 'Ezra', chapters: 10), BibleBook(number: 16, name: 'Nehemiah', chapters: 13), BibleBook(number: 17, name: 'Esther', chapters: 10), BibleBook(number: 18, name: 'Job', chapters: 42), BibleBook(number: 19, name: 'Psalms', chapters: 150), BibleBook(number: 20, name: 'Proverbs', chapters: 31), BibleBook(number: 21, name: 'Ecclesiastes', chapters: 12), BibleBook(number: 22, name: 'Song of Songs', chapters: 8), BibleBook(number: 23, name: 'Isaiah', chapters: 66), BibleBook(number: 24, name: 'Jeremiah', chapters: 52), BibleBook(number: 25, name: 'Lamentations', chapters: 5), BibleBook(number: 26, name: 'Ezekiel', chapters: 48), BibleBook(number: 27, name: 'Daniel', chapters: 12), BibleBook(number: 28, name: 'Hosea', chapters: 14), BibleBook(number: 29, name: 'Joel', chapters: 3), BibleBook(number: 30, name: 'Amos', chapters: 9), BibleBook(number: 31, name: 'Obadiah', chapters: 1), BibleBook(number: 32, name: 'Jonah', chapters: 4), BibleBook(number: 33, name: 'Micah', chapters: 7), BibleBook(number: 34, name: 'Nahum', chapters: 3), BibleBook(number: 35, name: 'Habakkuk', chapters: 3), BibleBook(number: 36, name: 'Zephaniah', chapters: 3), BibleBook(number: 37, name: 'Haggai', chapters: 2), BibleBook(number: 38, name: 'Zechariah', chapters: 14), BibleBook(number: 39, name: 'Malachi', chapters: 4), BibleBook(number: 40, name: 'Matthew', chapters: 28), BibleBook(number: 41, name: 'Mark', chapters: 16), BibleBook(number: 42, name: 'Luke', chapters: 24), BibleBook(number: 43, name: 'John', chapters: 21), BibleBook(number: 44, name: 'Acts', chapters: 28), BibleBook(number: 45, name: 'Romans', chapters: 16), BibleBook(number: 46, name: '1 Corinthians', chapters: 16), BibleBook(number: 47, name: '2 Corinthians', chapters: 13), BibleBook(number: 48, name: 'Galatians', chapters: 6), BibleBook(number: 49, name: 'Ephesians', chapters: 6), BibleBook(number: 50, name: 'Philippians', chapters: 4), BibleBook(number: 51, name: 'Colossians', chapters: 4), BibleBook(number: 52, name: '1 Thessalonians', chapters: 5), BibleBook(number: 53, name: '2 Thessalonians', chapters: 3), BibleBook(number: 54, name: '1 Timothy', chapters: 6), BibleBook(number: 55, name: '2 Timothy', chapters: 4), BibleBook(number: 56, name: 'Titus', chapters: 3), BibleBook(number: 57, name: 'Philemon', chapters: 1), BibleBook(number: 58, name: 'Hebrews', chapters: 13), BibleBook(number: 59, name: 'James', chapters: 5), BibleBook(number: 60, name: '1 Peter', chapters: 5), BibleBook(number: 61, name: '2 Peter', chapters: 3), BibleBook(number: 62, name: '1 John', chapters: 5), BibleBook(number: 63, name: '2 John', chapters: 1), BibleBook(number: 64, name: '3 John', chapters: 1), BibleBook(number: 65, name: 'Jude', chapters: 1), BibleBook(number: 66, name: 'Revelation', chapters: 22),
];

/// Book names used in French Bibles, in the same order as [bibleBooks].
const frenchBookNames = [
  'Genèse', 'Exode', 'Lévitique', 'Nombres', 'Deutéronome', 'Josué', 'Juges', 'Ruth', '1 Samuel', '2 Samuel', '1 Rois', '2 Rois', '1 Chroniques', '2 Chroniques', 'Esdras', 'Néhémie', 'Esther', 'Job', 'Psaumes', 'Proverbes', 'Ecclésiaste', 'Cantique des cantiques', 'Ésaïe', 'Jérémie', 'Lamentations', 'Ézéchiel', 'Daniel', 'Osée', 'Joël', 'Amos', 'Abdias', 'Jonas', 'Michée', 'Nahum', 'Habakuk', 'Sophonie', 'Aggée', 'Zacharie', 'Malachie',
  'Matthieu', 'Marc', 'Luc', 'Jean', 'Actes', 'Romains', '1 Corinthiens', '2 Corinthiens', 'Galates', 'Éphésiens', 'Philippiens', 'Colossiens', '1 Thessaloniciens', '2 Thessaloniciens', '1 Timothée', '2 Timothée', 'Tite', 'Philémon', 'Hébreux', 'Jacques', '1 Pierre', '2 Pierre', '1 Jean', '2 Jean', '3 Jean', 'Jude', 'Apocalypse',
];

/// French Bibles divide Joel into 4 chapters and Malachi into 3.
const frenchChapterCounts = {29: 4, 39: 3};

/// Book names used in Kinyarwanda Bibles, in the same order as [bibleBooks].
const kinyarwandaBookNames = [
  'Itangiriro', 'Kuva', 'Abalewi', 'Kubara', 'Gutegeka kwa kabiri', 'Yosuwa', 'Abacamanza', 'Rusi', '1 Samweli', '2 Samweli', '1 Abami', '2 Abami', '1 Ngoma', '2 Ngoma', 'Ezira', 'Nehemiya', 'Esiteri', 'Yobu', 'Zaburi', 'Imigani', 'Umubwiriza', 'Indirimbo ya Salomo', 'Yesaya', 'Yeremiya', 'Amaganya', 'Ezekiyeli', 'Daniyeli', 'Hoseya', 'Yoweli', 'Amosi', 'Obadiya', 'Yona', 'Mika', 'Nahumu', 'Habakuki', 'Zefaniya', 'Hagayi', 'Zekariya', 'Malaki',
  'Matayo', 'Mariko', 'Luka', 'Yohana', 'Ibyakozwe n’Intumwa', 'Abaroma', '1 Abakorinto', '2 Abakorinto', 'Abagalatiya', 'Abefeso', 'Abafilipi', 'Abakolosayi', '1 Abatesalonike', '2 Abatesalonike', '1 Timoteyo', '2 Timoteyo', 'Tito', 'Filemoni', 'Abaheburayo', 'Yakobo', '1 Petero', '2 Petero', '1 Yohana', '2 Yohana', '3 Yohana', 'Yuda', 'Ibyahishuwe',
];
