import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sync.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forceOffline = ref.watch(forceOfflineProvider);
    return ListView(
      children: [
        SwitchListTile(
          title: const Text('Paksa mode offline'),
          subtitle: const Text(
            'Mencegah refresh jaringan agar demo dapat diuji tanpa Wi-Fi.',
          ),
          value: forceOffline,
          onChanged: (_) async {
            final wasOffline = ref.read(forceOfflineProvider);
            ref.read(forceOfflineProvider.notifier).toggle();
            if (wasOffline) {
              await ref
                  .read(postsCacheProvider.notifier)
                  .refreshPostsInBackground();
            }
          },
        ),
      ],
    );
  }
}
