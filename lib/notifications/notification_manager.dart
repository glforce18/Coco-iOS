import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Notification IDs — stable per category so re-scheduling cancels the
/// previous instance automatically.
class NotifIds {
  static const int lifeFull = 1001;
  static const int dailyReminder = 1002;
  static const int eggReady = 1003;
  static const int dailyReward = 1004;
  // FCM payloads use IDs 2000+ to avoid collision.
}

/// Quiet hours — outside [09:00, 21:00) we suppress all local notifications.
/// Hard-coded per user requirement (CLAUDE.md decision 2026-05-09).
class QuietHours {
  static const int startHour = 9;
  static const int endHour = 21;
  static bool isQuiet(DateTime t) {
    final h = t.hour;
    return h < startHour || h >= endHour;
  }

  /// If [t] falls in quiet hours, push it forward to the next 09:00.
  /// Otherwise return [t] unchanged.
  static DateTime nudgeIntoActiveWindow(DateTime t) {
    if (!isQuiet(t)) return t;
    final base = DateTime(t.year, t.month, t.day, startHour);
    if (t.hour >= endHour) {
      // Past today's window — push to tomorrow 09:00.
      return base.add(const Duration(days: 1));
    }
    // Before today's window (early morning).
    return base;
  }
}

/// Singleton facade over flutter_local_notifications + permission flow.
///
/// All scheduling goes through here so quiet-hour gating + master-toggle
/// are enforced in one place.
class NotificationManager {
  NotificationManager._();
  static final NotificationManager instance = NotificationManager._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Master toggle — kept in sync with PlayerProgress.notifsEnabled by the
  /// provider layer. When false, every schedule call no-ops.
  bool masterEnabled = true;

  /// Per-type toggles (mirrored from PlayerProgress).
  bool lifeFullEnabled = true;
  bool dailyEnabled = true;
  bool eggEnabled = true;
  bool dailyRewardEnabled = true;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    // Best-effort local timezone detection. Flutter doesn't expose the
    // device timezone synchronously without a platform channel, so we
    // fall back to Europe/Istanbul (primary user base) if needed.
    try {
      final name = DateTime.now().timeZoneName;
      // tz can throw on unknown names — guard.
      tz.setLocalLocation(tz.getLocation(_mapTimezoneName(name)));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      // We request explicitly via permission_handler for unified flow.
    );
    final settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onTap,
      onDidReceiveBackgroundNotificationResponse: _onTapBg,
    );

    if (Platform.isAndroid) {
      // Create the channel up front so the first schedule call doesn't
      // race with channel registration.
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        'coco_default',
        'Coco bildirimleri',
        description: 'Can yenileme, yumurta hatırlatma, günlük etkinlik.',
        importance: Importance.defaultImportance,
        enableVibration: true,
      ));
    }

    _initialized = true;
  }

  /// Ask the OS for permission. Returns true if granted.
  /// On iOS this triggers the system popup. Android 13+ uses the runtime
  /// permission; older Android grants by default.
  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return false;
  }

  /// Whether the OS has granted permission (does NOT trigger any popup).
  Future<bool> isPermissionGranted() async {
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final res = await ios?.checkPermissions();
      return res?.isAlertEnabled ?? false;
    }
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted;
    }
    return false;
  }

  // ─── Schedulers ─────────────────────────────────────────────────────

  /// Schedule the "all 5 lives full" notif at [readyAt]. If [readyAt] is in
  /// the past, fires almost immediately. Cancels any previously-scheduled
  /// life-full notif.
  Future<void> scheduleLifeFull(DateTime readyAt) async {
    await _plugin.cancel(NotifIds.lifeFull);
    if (!masterEnabled || !lifeFullEnabled) return;

    final at = QuietHours.nudgeIntoActiveWindow(readyAt);
    await _zonedSchedule(
      id: NotifIds.lifeFull,
      title: 'Canların doldu! 🎮',
      body: 'Coco seni bekliyor — yeni bölümler hazır.',
      payload: 'route:/map',
      at: at,
    );
  }

  /// Schedule the daily ~19:00 reminder for tomorrow (if user hasn't played).
  Future<void> scheduleDailyReminder({int hour = 19, int minute = 0}) async {
    await _plugin.cancel(NotifIds.dailyReminder);
    if (!masterEnabled || !dailyEnabled) return;

    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    final at = QuietHours.nudgeIntoActiveWindow(next);

    await _zonedSchedule(
      id: NotifIds.dailyReminder,
      title: 'Coco seni özledi! 🐦',
      body: 'Bir bölüm oyna, yumurtaların ısınsın.',
      payload: 'route:/map',
      at: at,
    );
  }

  /// Schedule egg-ready reminder. Pass [readyAt] = approximate time when an
  /// egg will hit ready state (heat ≥ 50). Caller computes from level pace.
  Future<void> scheduleEggReady(DateTime readyAt) async {
    await _plugin.cancel(NotifIds.eggReady);
    if (!masterEnabled || !eggEnabled) return;
    final at = QuietHours.nudgeIntoActiveWindow(readyAt);
    await _zonedSchedule(
      id: NotifIds.eggReady,
      title: 'Yumurtan çatlamak üzere! 🥚',
      body: 'Yuva\'ya gel, kim çıkacak gör!',
      payload: 'route:/nest',
      at: at,
    );
  }

  /// Schedule daily-reward reminder for the next reset (00:00 next day).
  Future<void> scheduleDailyRewardReady() async {
    await _plugin.cancel(NotifIds.dailyReward);
    if (!masterEnabled || !dailyRewardEnabled) return;
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    // Reward notifs target the morning, not midnight — shift to 09:30.
    final at = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 30);

    await _zonedSchedule(
      id: NotifIds.dailyReward,
      title: 'Günlük ödülün hazır! 🎁',
      body: 'Çark ve hediyen seni bekliyor.',
      payload: 'route:/spin',
      at: at,
    );
  }

  /// Cancel every scheduled local notification.
  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> cancelLifeFull() => _plugin.cancel(NotifIds.lifeFull);
  Future<void> cancelDaily() => _plugin.cancel(NotifIds.dailyReminder);
  Future<void> cancelEgg() => _plugin.cancel(NotifIds.eggReady);
  Future<void> cancelDailyReward() => _plugin.cancel(NotifIds.dailyReward);

  // ─── Internal ───────────────────────────────────────────────────────

  Future<void> _zonedSchedule({
    required int id,
    required String title,
    required String body,
    required String payload,
    required DateTime at,
  }) async {
    final tzAt = tz.TZDateTime.from(at, tz.local);
    const android = AndroidNotificationDetails(
      'coco_default',
      'Coco bildirimleri',
      channelDescription: 'Can yenileme, yumurta hatırlatma, günlük etkinlik.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: android, iOS: ios);

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzAt,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[notif] schedule failed: $e');
    }
  }

  static String _mapTimezoneName(String raw) {
    // Common TR locale timezones map — fall back to Istanbul.
    const aliases = {
      '+03': 'Europe/Istanbul',
      'TRT': 'Europe/Istanbul',
      'UTC': 'UTC',
      'GMT': 'UTC',
    };
    return aliases[raw] ?? 'Europe/Istanbul';
  }
}

@pragma('vm:entry-point')
void _onTapBg(NotificationResponse response) {
  // Background isolate — no widget tree access. The route is consumed
  // when the app launches via initial notification.
}

void _onTap(NotificationResponse response) {
  // Foreground tap — router consumption is wired by main.dart via a
  // pending-route holder so we don't reach into context here.
  PendingNotifRoute.set(response.payload);
}

/// Lightweight bridge so main.dart can read the route payload after the
/// router is mounted. Set by the notif tap callback, consumed once.
class PendingNotifRoute {
  static String? _route;
  static void set(String? raw) {
    if (raw == null || !raw.startsWith('route:')) return;
    _route = raw.substring('route:'.length);
  }

  static String? consume() {
    final r = _route;
    _route = null;
    return r;
  }
}
