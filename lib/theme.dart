import 'package:flutter/material.dart';

/// Ijambo brand colours. Keep in sync with android/app/src/main/res/values/colors.xml.
class Brand {
  static const green = Color(0xFF1E4D42);
  static const greenDeep = Color(0xFF143A31);
  static const gold = Color(0xFFD4A657);
  static const goldInk = Color(0xFF94661F);
  static const paper = Color(0xFFFBF7EE);
  static const card = Color(0xFFFFFDF8);
  static const line = Color(0xFFECE3D0);
  static const ink = Color(0xFF1F2A27);
  static const muted = Color(0xFF6B7672);
  static const night = Color(0xFF0F1715);
  static const nightCard = Color(0xFF17221E);
  static const nightLine = Color(0xFF26332E);
  static const nightInk = Color(0xFFE9E3D5);
  static const nightMuted = Color(0xFF9AA7A2);
  static const mint = Color(0xFF8FC5B4);
}

/// Font used for Scripture text (bundled in assets/fonts).
const scriptureFont = 'Crimson';

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: Brand.green, brightness: brightness).copyWith(
    primary: dark ? Brand.mint : Brand.green,
    onPrimary: dark ? Brand.night : Colors.white,
    secondary: Brand.gold,
    surface: dark ? Brand.night : Brand.paper,
    onSurface: dark ? Brand.nightInk : Brand.ink,
    onSurfaceVariant: dark ? Brand.nightMuted : Brand.muted,
    outlineVariant: dark ? Brand.nightLine : Brand.line,
  );
  final card = dark ? Brand.nightCard : Brand.card;
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: card,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: card,
      indicatorColor: dark ? Brand.green : const Color(0xFFE3EEE9),
      height: 68,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurface),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: card, showDragHandle: true),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

/// Small uppercase label used above sections.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).brightness == Brightness.dark ? Brand.gold : Brand.goldInk,
          ),
        ),
      );
}
