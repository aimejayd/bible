# Ijambo Bible

A Flutter starter app for reading Scripture in English, French, and Kinyarwanda.

## Included

- Language switcher for English, Français, and Kinyarwanda
- Genesis 1 reading view with translated sample text
- Live Genesis 1 loading from GetBible for English WEB and French Darby
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

English WEB and French Darby are loaded from GetBible's public API. The bundled passages provide an offline fallback. Kinyarwanda remains a sample until a Bible Society of Rwanda / Digital Bible Library licence and API credential are approved; do not ship a complete Kinyarwanda edition without that permission.
