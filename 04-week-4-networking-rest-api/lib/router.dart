import 'package:go_router/go_router.dart';

import 'pages/pages_post_page.dart';
import 'pages/post_detail_page.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const PagedPostPage(),
    ),
    GoRoute(
      path: '/post/:id',
      builder: (context, state) {
        final postId = int.parse(state.pathParameters['id']!);
        return PostDetailPage(postId: postId);
      },
    ),
  ],
);
