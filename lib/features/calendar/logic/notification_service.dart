import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../data/models/reminder.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;
  bool get _supportsScheduling =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _reminderChannel =
  AndroidNotificationChannel(
    'journal_reminders',
    'Journal Reminders',
    description: 'Notifications pour les rappels du journal',
    importance: Importance.max,
  );

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );
    await _notificationsPlugin.initialize(initializationSettings);

    if (_supportsScheduling) {
      // Android
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.createNotificationChannel(_reminderChannel);
      await androidImpl?.requestNotificationsPermission();

      // iOS
      final iosImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);

      // macOS (optionnel)
      final macImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      await macImpl?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _initialized = true;
  }

  Future<void> scheduleReminder(Reminder reminder) async {
    if (!_initialized) await init();

    final scheduledAt = reminder.scheduledAt;
    if (scheduledAt.isBefore(DateTime.now())) return;

    // Si la plateforme ne supporte pas zonedSchedule (Windows/Web) → fallback
    if (!_supportsScheduling) {
      await _notificationsPlugin.show(
        reminder.id.hashCode,
        reminder.title,
        reminder.description,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'journal_reminders', 'Journal Reminders',
            channelDescription: 'Notifications pour les rappels du journal',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: reminder.id,
      );
      return;
    }

    // Planification normale (Android/iOS/macOS)
    final tzScheduledDate = tz.TZDateTime.from(scheduledAt, tz.local);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _reminderChannel.id,
        _reminderChannel.name,
        channelDescription: _reminderChannel.description,
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _notificationsPlugin.zonedSchedule(
      reminder.id.hashCode,
      reminder.title,
      reminder.description,
      tzScheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      payload: reminder.id,
    );
  }


  Future<void> cancelReminder(String id) async {
    // Sur Windows/Web, il n'y a pas d'implémentation → on sort
    if (!_supportsScheduling) return;

    // Sinon Android/iOS/macOS
    await _notificationsPlugin.cancel(id.hashCode);
  }

  Future<void> rescheduleReminder(Reminder reminder) async {
    if (!_supportsScheduling) return;

    await cancelReminder(reminder.id);
    if (reminder.isActive) {
      await scheduleReminder(reminder);
    }
  }
}
