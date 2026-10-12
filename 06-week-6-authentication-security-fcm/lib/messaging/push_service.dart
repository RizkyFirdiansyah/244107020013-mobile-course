import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final pendingDeepLinkNotifier = ValueNotifier<String?>(null);
String? pendingDeepLink;

const _channel = AndroidNotificationChannel(
  'campus_notifications',
  'Campus notifications',
  description: 'Notifikasi pengumuman kampus',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Notification payload ditampilkan sistem. Navigasi dilakukan saat notifikasi
  // diklik melalui onMessageOpenedApp atau getInitialMessage.
}

class PushService {
  PushService({FirebaseMessaging? messaging, FlutterLocalNotificationsPlugin? local})
    : _messaging = messaging ?? FirebaseMessaging.instance,
      _local = local ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _local;

  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<void> initialize({
    required Future<void> Function(String token) onToken,
  }) async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
    await _local.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        _setRoute(response.payload);
      },
    );

    final initialMessage = await _messaging.getInitialMessage();
    _setRouteFromMessage(initialMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_setRouteFromMessage);
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    final token = await _messaging.getToken();
    if (token != null) await onToken(token);
    _messaging.onTokenRefresh.listen(onToken);
    await subscribeToAnnouncementsTopic();
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _local.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: _routeFromData(message.data),
    );
  }

  Future<void> subscribeToAnnouncementsTopic() {
    return _messaging.subscribeToTopic('pengumuman-kampus');
  }

  Future<void> unsubscribeFromAnnouncementsTopic() {
    return _messaging.unsubscribeFromTopic('pengumuman-kampus');
  }

  Future<String?> getTokenPreview() async {
    if (kIsWeb) return null;
    final token = await _messaging.getToken();
    if (token == null) return null;
    final visibleLength = token.length < 12 ? token.length : 12;
    return '${token.substring(0, visibleLength)}...';
  }

  static String? _routeFromData(Map<String, dynamic> data) {
    final route = data['route'] ?? data['deep_link'];
    return route is String && route.isNotEmpty ? route : null;
  }

  static void _setRouteFromMessage(RemoteMessage? message) {
    _setRoute(message == null ? null : _routeFromData(message.data));
  }

  static void _setRoute(String? route) {
    if (route == null || route.isEmpty) return;
    pendingDeepLink = route;
    pendingDeepLinkNotifier.value = route;
  }
}

final pushService = PushService();
