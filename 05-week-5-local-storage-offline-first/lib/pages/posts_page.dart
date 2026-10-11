import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sync.dart';

class PostsPage extends ConsumerWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(postsCacheProvider);
    final forceOffline = ref.watch(forceOfflineProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(postsCacheProvider.notifier).refreshPostsInBackground(),
      child: posts.when(
        loading: () => ListView(
          children: [
            SizedBox(height: 240),
            Center(child: CircularProgressIndicator()),
          ],
        ),
        error: (error, _) => ListView(
          children: [
            const SizedBox(height: 180),
            Center(child: Text('Gagal membaca cache: $error')),
          ],
        ),
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 180),
                Center(
                  child: Text(
                    forceOffline
                        ? 'Belum ada cache posts.\nMatikan forceOffline untuk mengunduh data.'
                        : 'Belum ada posts.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          }
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final post = items[index];
              return ListTile(
                leading: CircleAvatar(child: Text('${post.id}')),
                title: Text(post.title),
                subtitle: Text(post.body),
              );
            },
          );
        },
      ),
    );
  }
}
