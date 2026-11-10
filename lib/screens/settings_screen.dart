import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../language.dart';
import '../theme.dart';
import '../notifications.dart';
import 'sheets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Settings', style: TextStyle(fontFamily: scriptureFont, fontSize: 28, fontWeight: FontWeight.w700))),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const SectionLabel('Reading'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.translate_rounded),
                title: const Text('Reading language'),
                subtitle: Text('${controller.language.label} · ${controller.language.edition}'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showLanguageSheet(context, controller),
              ),
            ),
            const SizedBox(height: 10),
            Card(child: Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: TextSizeControl(controller: controller))),
            const SizedBox(height: 24),
            const SectionLabel('Appearance'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.system, label: Text('Auto'), icon: Icon(Icons.brightness_auto_rounded)),
                      ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_rounded)),
                      ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_rounded)),
                    ],
                    selected: {controller.themeMode},
                    showSelectedIcon: false,
                    onSelectionChanged: (value) => controller.setThemeMode(value.first),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SectionLabel('Daily verse'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_active_outlined),
                    title: const Text('Morning reminder'),
                    subtitle: const Text('A notification with the verse of the day'),
                    value: controller.reminderEnabled,
                    onChanged: (value) async {
                      final ok = await controller.setReminderEnabled(value);
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Allow notifications for Ijambo Bible in your phone settings to get the daily verse.')),
                        );
                      }
                    },
                  ),
                  if (controller.reminderEnabled) ...[
                    const Divider(indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.schedule_rounded),
                      title: const Text('Reminder time'),
                      trailing: Text(formatTime(controller.reminderTime), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: controller.reminderTime);
                        if (picked != null) await controller.setReminderTime(picked);
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionLabel('Offline'),
            const Card(
              child: ListTile(
                leading: Icon(Icons.offline_pin_rounded, color: Brand.gold),
                title: Text('Works without internet'),
                subtitle: Text('The full English and French Bibles are stored on your phone.'),
              ),
            ),
            const SizedBox(height: 24),
            const SectionLabel('About'),
            Card(
              child: Column(
                children: [
                  const ListTile(title: Text('Ijambo Bible'), subtitle: Text('Version 1.0 · English · Français · Kinyarwanda')),
                  const Divider(indent: 16, endIndent: 16),
                  ListTile(
                    title: const Text('Bible texts'),
                    subtitle: Text(
                      '${BibleLanguage.english.edition} and ${BibleLanguage.french.edition} (1885) are in the public domain. '
                      'Kinyarwanda ${BibleLanguage.kinyarwanda.edition} is a preview pending permission from the Bible Society of Rwanda.',
                    ),
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  const ListTile(title: Text('Typeface'), subtitle: Text('Crimson Text, SIL Open Font License')),
                ],
              ),
            ),
          ],
        ),
      );
}
