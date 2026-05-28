// Module 1 – Context-Aware Smart Notification Engine
// Implements Rule A (standard reminder), Rule B (45-min escalation),
// and Rule C (7-day streak celebration) using flutter_local_notifications.

// packages: flutter_local_notifications, timezone

import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/medication_model.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  late FlutterLocalNotificationsPlugin _plugin;

  // Android notification channel IDs
  static const _channelStandard   = 'bp_mitra_standard';
  static const _channelEscalation = 'bp_mitra_escalation';
  static const _channelStreak     = 'bp_mitra_streak';

  Future<void> initialize(FlutterLocalNotificationsPlugin plugin) async {
    _plugin = plugin;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create channels for Android 8.0+ (Oreo+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelStandard,
          'Medication Reminders',
          description: 'Standard scheduled medication dose alerts',
          importance: Importance.high,
        ));

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelEscalation,
          'Critical BP Alerts',
          description: 'Escalation alerts for overdue critical medications',
          importance: Importance.max,
        ));

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelStreak,
          'Streak Achievements',
          description: 'Behavioral nudge rewards for medication streak milestones',
          importance: Importance.defaultImportance,
        ));
  }

  void _onNotificationTap(NotificationResponse response) {
    // Navigation handled externally via GoRouter; notification payload
    // carries the route path that the app shell dispatches on resume.
  }

  // ── Rule A: Standard Dose Reminder ─────────────────────────────────────
  // Schedules an exact-time notification at the medication's scheduled_time.
  Future<void> scheduleStandardReminder({
    required MedicationSchedule schedule,
    required DateTime scheduledDateTime,
  }) async {
    final tzDateTime = tz.TZDateTime.from(scheduledDateTime, tz.local);
    final notificationId = schedule.id.hashCode & 0x7FFFFFFF;

    await _plugin.zonedSchedule(
      notificationId,
      'BP Mitra: Medication Reminder',
      "It's time for your ${schedule.displayDosage} dose. Tap to confirm.",
      tzDateTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelStandard,
          'Medication Reminders',
          channelDescription: 'Standard scheduled medication dose alerts',
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'Medication reminder',
          styleInformation: const BigTextStyleInformation(''),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: '/medications',
    );
  }

  // ── Rule B: Escalation Alert (45-minute window) ─────────────────────────
  // Fires a persistent high-priority alert when a critical dose is not
  // confirmed as Taken within 45 minutes of the scheduled trigger time.
  Future<void> scheduleEscalationAlert({
    required MedicationSchedule schedule,
    required DateTime scheduledDateTime,
  }) async {
    if (!schedule.isCritical) return;

    final escalationTime = scheduledDateTime.add(const Duration(minutes: 45));
    final tzEscalation = tz.TZDateTime.from(escalationTime, tz.local);

    // Escalation ID is offset from standard ID to avoid collision.
    final notificationId = (schedule.id.hashCode & 0x7FFFFFFF) + 1000000;

    await _plugin.zonedSchedule(
      notificationId,
      'BP Mitra Warning: Critical Medication Overdue',
      'Critical BP medication dose is overdue. Please log your status '
      'immediately to maintain cardiovascular stability.',
      tzEscalation,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelEscalation,
          'Critical BP Alerts',
          channelDescription: 'Escalation alerts for overdue critical medications',
          importance: Importance.max,
          priority: Priority.max,
          ongoing: true,         // Persistent until dismissed
          autoCancel: false,
          fullScreenIntent: true,
          ticker: 'Critical medication overdue',
          color: const Color(0xFFE53E3E),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: '/medications',
    );
  }

  // Cancel escalation notification after user logs a dose as Taken.
  Future<void> cancelEscalationAlert(String scheduleId) async {
    final notificationId = (scheduleId.hashCode & 0x7FFFFFFF) + 1000000;
    await _plugin.cancel(notificationId);
  }

  // ── Rule C: 7-Day Streak Milestone ──────────────────────────────────────
  // Fires a behavioral nudge when the adherence engine detects 7 consecutive
  // days of 100% medication compliance.
  Future<void> fireStreakMilestoneNotification() async {
    await _plugin.show(
      999999, // Fixed ID; only one streak notification at a time
      'BP Mitra: 7-Day Streak Achieved!',
      'Excellent focus! You\'ve maintained a 7-day streak. '
      'Your vascular compliance metrics look highly stable!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelStreak,
          'Streak Achievements',
          channelDescription: 'Behavioral nudge rewards for streak milestones',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: const Color(0xFF1543A4),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
      ),
      payload: '/medications',
    );
  }

  // Cancel all pending notifications for a given schedule (e.g., on deactivation).
  Future<void> cancelScheduleNotifications(String scheduleId) async {
    final standardId = scheduleId.hashCode & 0x7FFFFFFF;
    final escalationId = standardId + 1000000;
    await _plugin.cancel(standardId);
    await _plugin.cancel(escalationId);
  }
}
