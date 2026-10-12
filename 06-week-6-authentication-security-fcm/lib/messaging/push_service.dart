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
  // Notifikasi berisi notification payload ditampilkan oleh Android.
  // Handler ini tetap diperlukan untuk data payload saat aplikasi background.
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
  _setDeepLinkFromMessage(initialMessage);
  FirebaseMessaging.onMessageOpenedApp.listen(_setDeepLinkFromMessage);

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
      payload: message.data['deep_link'] as String?,
    );
  });
}

String? pendingDeepLink;

void _setDeepLinkFromMessage(RemoteMessage? message) {
  final deepLink = message?.data['deep_link'] as String?;
  if (deepLink == null || deepLink.isEmpty) return;
  pendingDeepLink = deepLink;
  pendingDeepLinkNotifier.value = deepLink;
}

Future<void> initFcmToken({
  required Future<void> Function(String token) onToken,
}) async {
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) await onToken(token);

  FirebaseMessaging.instance.onTokenRefresh.listen(onToken);
  await FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');
}

Future<String?> getFcmTokenPreview() async {
  final token = await FirebaseMessaging.instance.getToken();
  if (token == null) return null;
  final visibleLength = token.length < 12 ? token.length : 12;
  return '${token.substring(0, visibleLength)}...';
}
