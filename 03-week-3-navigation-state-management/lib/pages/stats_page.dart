import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/stats_provider.dart';

// ConsumerWidget memberi akses ke Riverpod tanpa Consumer bertingkat.
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // watch hanya dipakai di build agar UI bereaksi terhadap perubahan async state.
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik')),
      // when menangani ketiga kemungkinan AsyncValue secara eksplisit.
      body: statsAsync.when(
        // Spinner ditampilkan selama request dua detik masih berlangsung.
        loading: () => const Center(child: CircularProgressIndicator()),
        // Error menampilkan pesan dan tombol yang mengulang request provider.
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Gagal memuat: $error'),
              const SizedBox(height: 12),
              FilledButton(
                // read dipakai di callback karena callback tidak membangun UI.
                onPressed: () => ref.read(statsProvider.notifier).retry(),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
        // Success menampilkan tiga item statistik dalam ListView.
        data: (stats) => ListView.builder(
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final statistic = stats[index];
            return ListTile(
              title: Text(statistic.label),
              trailing: Text(statistic.value.toString()),
            );
          },
        ),
      ),
    );
  }
}
