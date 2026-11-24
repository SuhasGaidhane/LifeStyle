import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import 'api_service.dart';
import 'session_service.dart';

/// Handles messages that arrive while the app is in the background or
/// terminated. Must be a top-level function annotated for the VM.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Notification-type messages are shown by the OS automatically. Nothing
  // required here unless you process data-only messages in the background.
  debugPrint('FCM background message: ${message.messageId}');
}

/// Wires up Firebase Cloud Messaging + local notifications:
///  - requests permission
///  - shows foreground messages as local notifications
///  - registers the device token with the backend
///  - exposes taps for navigation
class NotificationService extends GetxService {
  final _fln = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'lse_default_channel',
    'General Notifications',
    description: 'Posts, likes, follows and app updates',
    importance: Importance.high,
  );

  String? token;

  /// Call once, after Firebase.initializeApp() in main().
  /// Fully guarded — any failure (missing config, no Play Services) is
  /// swallowed so it never blocks app startup.
  Future<NotificationService> init() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // 1. Permission (iOS + Android 13+).
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      // 2. Local notifications (used to render foreground messages).
      await _initLocalNotifications();

      // 3. Foreground messages → show a local notification.
      FirebaseMessaging.onMessage.listen(_showForeground);

      // 4. Taps that opened the app from background / terminated.
      FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);
      final initial = await messaging.getInitialMessage();
      if (initial != null) _onOpened(initial);

      // 5. Token — cache it and push to the backend when logged in.
      token = await messaging.getToken();
      if (token != null) await _syncToken(token!);
      messaging.onTokenRefresh.listen((t) {
        token = t;
        _syncToken(t);
      });

      // 6. Subscribe to the broadcast topic so backend can notify everyone
      //    (e.g. new posts) with a single call.
      await messaging.subscribeToTopic('all_users');
    } catch (e) {
      debugPrint('NotificationService init failed: $e');
    }
    return this;
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _fln.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload != null && payload.isNotEmpty) {
          _handlePayload(jsonDecode(payload) as Map<String, dynamic>);
        }
      },
    );
    // Create the Android channel so high-importance heads-up shows.
    await _fln
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  void _showForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return; // data-only → skip (or handle silently)
    _fln.show(
      n.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _onOpened(RemoteMessage message) => _handlePayload(message.data);

  /// Routes a notification tap based on its data payload.
  /// Extend with your own `type`/`id` conventions as the backend grows.
  void _handlePayload(Map<String, dynamic> data) {
    // Example: {"type":"post","id":"42"} could Get.toNamed the post viewer.
    debugPrint('Notification tapped with data: $data');
  }

  String get _platform => Platform.isIOS ? 'ios' : 'android';

  Future<void> _syncToken(String t) async {
    try {
      final session = Get.find<SessionService>();
      final uid = session.userId;
      if (uid == null) return; // not logged in yet; synced again after login
      await Get.find<ApiService>().saveFcmToken('$uid', t, platform: _platform);
    } catch (_) {
      // Non-fatal — token will re-sync on next launch / refresh / login.
    }
  }

  /// Call right after a successful login so the token is attached to the
  /// freshly logged-in user.
  Future<void> syncTokenAfterLogin() async {
    if (token != null) await _syncToken(token!);
  }
}
