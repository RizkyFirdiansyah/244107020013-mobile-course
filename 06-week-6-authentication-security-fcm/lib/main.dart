import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';
import 'messaging/push_service.dart';
import 'pages/announcement_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'providers/auth_provider.dart';
import 'data/api_client.dart';
import 'routes.dart';

final container = ProviderContainer();
final fcmTokenProvider = StateProvider<String?>((ref) => null);

String maskToken(String token) {
  final visibleLength = token.length < 12 ? token.length : 12;
  return '${token.substring(0, visibleLength)}...';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  return GoRouter(
    refreshListenable: pendingDeepLinkNotifier,
    redirect: (context, state) {
      final deepLink = pendingDeepLinkNotifier.value;
      final loggedIn = authState.value ?? false;
      final goingLogin = state.matchedLocation == AppRoutes.login;
      if (loggedIn && deepLink != null && deepLink != state.matchedLocation) {
        pendingDeepLinkNotifier.value = null;
        pendingDeepLink = null;
        return deepLink;
      }
      if (!loggedIn && !goingLogin) return AppRoutes.login;
      if (loggedIn && goingLogin) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
      GoRoute(path: AppRoutes.home, builder: (_, _) => const HomePage()),
      GoRoute(
        path: AppRoutes.announcementPattern,
        builder: (_, state) =>
            AnnouncementPage(id: state.pathParameters['id'] ?? ''),
      ),
    ],
  );
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: kIsWeb ? DefaultFirebaseOptions.web : null,
  );
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await pushService.requestPermission();
    await pushService.initialize(
      onToken: (token) async {
        container.read(fcmTokenProvider.notifier).state = token;
        debugPrint('[FCM] token dikirim ke backend: ${maskToken(token)}');
        // Kirim token ke backend. Endpoint didokumentasikan: POST /devices.
        // Backend contoh belum tersedia, jadi kegagalan diabaikan.
        try {
          final dio = buildApiClient(
            container.read(tokenStoreProvider),
            container.read(authRepositoryProvider),
          );
          await dio.post(
            '/devices',
            data: {'fcm_token': token, 'platform': 'android'},
          );
        } catch (_) {
          // Diabaikan: token tetap ditampilkan (terpotong) di halaman debug.
        }
      },
    );
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authStateProvider);
    return MaterialApp.router(
      title: 'Campus Notify',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
