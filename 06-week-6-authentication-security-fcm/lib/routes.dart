abstract final class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const announcementPattern = '/pengumuman/:id';

  static String announcement(String id) => '/pengumuman/$id';
}

String routeFromMessage(Map<String, dynamic> data) {
  final value = data['route'];
  if (value is! String || value.trim().isEmpty) return AppRoutes.home;
  final route = value.trim();
  return route.startsWith('/') ? route : '/$route';
}
