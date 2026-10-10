import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/network_errors.dart';
import '../data/providers.dart';

class PostDetailPage extends ConsumerWidget {
  const PostDetailPage({required this.postId, super.key});

  final int postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(postDetailProvider(postId));

    return Scaffold(
      appBar: AppBar(title: Text('Post $postId')),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(friendlyErrorMessage(error)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(postDetailProvider(postId)),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
        data: (post) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(post.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text(post.body, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
