import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../language.dart';
import '../theme.dart';

Future<void> showLanguageSheet(BuildContext context, AppController controller) => showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text('Reading language', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ),
              ...BibleLanguage.values.map((language) {
                final selected = language == controller.language;
                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  selected: selected,
                  selectedTileColor: Brand.green.withValues(alpha: .08),
                  leading: CircleAvatar(
                    backgroundColor: selected ? Brand.green : Theme.of(context).colorScheme.outlineVariant,
                    foregroundColor: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    child: Text(language.short, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                  ),
                  title: Text(language.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(language == BibleLanguage.kinyarwanda ? '${language.edition} · preview' : language.edition),
                  trailing: selected ? const Icon(Icons.check_circle_rounded, color: Brand.gold) : null,
                  onTap: () {
                    controller.setLanguage(language);
                    Navigator.pop(sheetContext);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );

Future<void> showTextSizeSheet(BuildContext context, AppController controller) => showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => TextSizeControl(controller: controller),
          ),
        ),
      ),
    );

/// Slider with a live preview, used in the reader sheet and in Settings.
class TextSizeControl extends StatelessWidget {
  const TextSizeControl({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Text size', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text('In the beginning was the Word.',
              style: TextStyle(fontFamily: scriptureFont, fontSize: 21 * controller.textScale, height: 1.4)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('A', style: TextStyle(fontSize: 14)),
              Expanded(
                child: Slider(
                  value: controller.textScale,
                  min: .8,
                  max: 1.6,
                  divisions: 8,
                  label: '${(controller.textScale * 100).round()}%',
                  onChanged: controller.setTextScale,
                ),
              ),
              const Text('A', style: TextStyle(fontSize: 24)),
            ],
          ),
        ],
      );
}
