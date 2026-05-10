import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import 'package:patpat_game/notifications/notification_manager.dart';

/// FCM (server push) layer. Independent of NotificationManager so the
/// app stays functional when Firebase config is missing.
///
/// Server backend lives at https://ilacbilgi.org/coco-api/
/// (mirrors the Falaî push pattern — see /root/coco-push-service/).
class FcmManager {
  FcmManager._();
  static final FcmManager instance = FcmManager._();

  static const String _backendUrl = 'https://ilacbilgi.org/coco-api/tokens';

  bool _initialized = false;

  /// Bring up FCM: request permission, fetch token, register listeners.
  /// Safe no-op when Firebase isn't configured (`firebase_options.dart`
  /// missing). Calls [onToken] with the registered token (so the provider
  /// can persist it).
  Future<void> init({required Future<void> Function(String token) onToken}) async {
    if (_initialized) return;
    try {
      final messaging = FirebaseMessaging.instance;

      // iOS / Android 13+ permission. We do NOT show a custom popup here —
      // permission_handler is used at the in-game opt-in moment and that
      // covers FCM too on Android 13+ (POST_NOTIFICATIONS).
      if (Platform.isIOS) {
        await messaging.requestPermission(alert: true, badge: true, sound: true);
      }

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await onToken(token);
        _registerWithBackend(token);
      }

      messaging.onTokenRefresh.listen((newToken) async {
        await onToken(newToken);
        _registerWithBackend(newToken);
      });

      // Foreground push — relay to local plugin so user actually sees it.
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // App opened from a backgrounded push.
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);

      // App launched cold from a push.
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _onMessageOpened(initialMessage);
      }

      _initialized = true;
    } catch (e) {
      if (kDebugMode) debugPrint('[fcm] init failed: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage msg) async {
    final notif = msg.notification;
    if (notif == null) return;
    // Re-emit through local plugin so a banner shows while app is open.
    final plugin = FlutterLocalNotificationsPlugin();
    const androidDetails = AndroidNotificationDetails(
      'coco_default',
      'Coco bildirimleri',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    await plugin.show(
      msg.hashCode,
      notif.title,
      notif.body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: _payloadFromData(msg.data),
    );
  }

  void _onMessageOpened(RemoteMessage msg) {
    PendingNotifRoute.set(_payloadFromData(msg.data));
  }

  String? _payloadFromData(Map<String, dynamic> data) {
    final route = data['route'];
    if (route is String && route.isNotEmpty) return 'route:$route';
    return null;
  }

  void _registerWithBackend(String token) {
    // Fire-and-forget — backend may not exist yet (kept tolerant).
    () async {
      try {
        await http.post(
          Uri.parse(_backendUrl),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'token': token,
            'platform': Platform.operatingSystem,
            'app': 'coco',
          }),
        );
      } catch (e) {
        if (kDebugMode) debugPrint('[fcm] backend register failed: $e');
      }
    }();
  }
}
