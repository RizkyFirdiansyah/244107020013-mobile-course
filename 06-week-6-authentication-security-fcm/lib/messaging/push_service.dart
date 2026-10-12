import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final _local = FlutterLocalNotificationsPlugin();
final pendingDeepLinkNotifier = ValueNotifier<String?>(null);
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

Future<bool> requestNotificationPermission() async {
  final settings = await FirebaseMessaging.instance.requestPermission(
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

Future<void> initLocalNotifications() async {
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
      pendingDeepLink = response.payload;
      pendingDeepLinkNotifier.value = response.payload;
    },
  );

  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  _setRouteFromMessage(initialMessage);
  FirebaseMessaging.onMessageOpenedApp.listen(_setRouteFromMessage);

  FirebaseMessaging.onMessage.listen((message) async {
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
  });
}

String? pendingDeepLink;

String? _routeFromData(Map<String, dynamic> data) {
  final route = data['route'] ?? data['deep_link'];
  return route is String && route.isNotEmpty ? route : null;
}

void _setRouteFromMessage(RemoteMessage? message) {
  final route = message == null ? null : _routeFromData(message.data);
  if (route == null) return;
  pendingDeepLink = route;
  pendingDeepLinkNotifier.value = route;
}

Future<void> initFcmToken({
  required Future<void> Function(String token) onToken,
}) async {
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) await onToken(token);

  FirebaseMessaging.instance.onTokenRefresh.listen(onToken);
  await FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');
}

Future<void> unsubscribeFromAnnouncementsTopic() {
  return FirebaseMessaging.instance.unsubscribeFromTopic('pengumuman-kampus');
}

Future<String?> getFcmTokenPreview() async {
  if (kIsWeb) return null;
  final token = await FirebaseMessaging.instance.getToken();
  if (token == null) return null;
  final visibleLength = token.length < 12 ? token.length : 12;
  return '${token.substring(0, visibleLength)}...';
}
