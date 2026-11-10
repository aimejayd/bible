# Ijambo Bible

A Flutter starter app for reading Scripture in English, French, and Kinyarwanda.

## Included

- Branded splash screen and app icon (source in `design/`)
- Today screen: verse of the day, continue reading, browse Old and New Testament
- Reader with Crimson Text typeface, adjustable text size, tap a verse to copy it
- Full-screen book and chapter picker with search
- Remembers where you stopped reading; saved chapters with swipe to remove
- Light, dark or automatic appearance
- Full English (World English Bible) and French (Bible Darby, 1885) texts bundled, so every chapter works offline
- French and Kinyarwanda book names; French chapter numbering (Joel 4, Malachi 3)
- Kinyarwanda: Genesis 1 preview until the Bible Society of Rwanda text is licensed

## Build

Every push to `main` builds an APK on GitHub Actions and publishes it under Releases.
Locally: `flutter pub get` then `flutter build apk --release`.

## Data

English WEB and French Darby are read from `assets/bibles/<edition>/<book>.json`, built from the public-domain texts in [midvash/bible-data](https://github.com/midvash/bible-data). Each file is `{"c": [[[verse, "text"], ...], ...]}` with one list per chapter. Do not ship a complete Kinyarwanda edition without permission from the Bible Society of Rwanda.
