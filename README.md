# Ijambo Bible

A Flutter starter app for reading Scripture in English, French, and Kinyarwanda.

## Included

- Language switcher for English, Français, and Kinyarwanda
- Genesis 1 reading view with translated sample text
- Full English (World English Bible) and French (Bible Darby, 1885) texts bundled in the app, so every chapter works offline
- Book names and chapter numbering follow each language (French Joel has 4 chapters, Malachi 3)
- Verse of the day card
- Books, saved passages, and settings screens
- Material 3 interface designed for phones

## Run it

From this folder, use a Flutter SDK to generate the platform wrappers once and launch the app:

```powershell
flutter create .
flutter pub get
flutter run
```

English WEB and French Darby are read from `assets/bibles/<edition>/<book>.json`, built from the public-domain texts in [midvash/bible-data](https://github.com/midvash/bible-data). Each file is `{"c": [[[verse, "text"], ...], ...]}` with one list per chapter. GetBible's API is only used if a bundled chapter is missing. Kinyarwanda remains a sample until a Bible Society of Rwanda / Digital Bible Library licence and API credential are approved; do not ship a complete Kinyarwanda edition without that permission.
