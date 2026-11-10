import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'theme.dart';

/// One scheduled morning notification.
class VerseReminder {
  const VerseReminder({required this.when, required this.title, required this.body});
  final DateTime when;
  final String title;
  final String body;
}

/// Schedules the daily verse notifications on the phone.
///
/// Each verse is different, so instead of one repeating notification the app
/// schedules the next couple of weeks and tops them up every time it opens.
class VerseNotifications {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialised = false;

  Future<void> _init() async {
    if (_initialised) return;
    tz_data.initializeTimeZones();
    await _plugin.initialize(const InitializationSettings(android: AndroidInitializationSettings('ic_notification')));
    _initialised = true;
  }

  /// Asks for permission to show notifications (Android 13 and newer). Returns false if refused.
  Future<bool> requestPermission() async {
    await _init();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? true;
  }

  Future<void> cancelAll() async {
    await _init();
    await _plugin.cancelAll();
  }

  Future<void> schedule(List<VerseReminder> reminders) async {
    await _init();
    await _plugin.cancelAll();
    for (var i = 0; i < reminders.length; i++) {
      final r = reminders[i];
      await _plugin.zonedSchedule(
        i,
        r.title,
        r.body,
        tz.TZDateTime.from(r.when, tz.UTC),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_verse',
            'Verse of the day',
            channelDescription: 'A Bible verse every morning',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            color: Brand.green,
            styleInformation: BigTextStyleInformation(r.body, contentTitle: r.title),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}

/// Time of day helper for display, e.g. 7:00.
String formatTime(TimeOfDay time) => '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
