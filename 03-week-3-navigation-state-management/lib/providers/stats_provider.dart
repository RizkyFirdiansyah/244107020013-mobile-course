import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Satu baris data statistik yang akan ditampilkan oleh StatsPage.
class Statistic {
  const Statistic({required this.label, required this.value});

  final String label;
  final int value;
}

// AsyncNotifier mengelola data async sekaligus state loading, error, dan data.
class StatsNotifier extends AsyncNotifier<List<Statistic>> {
  // Random dapat diganti saat test agar skenario berhasil/gagal deterministik.
  StatsNotifier({Random? random}) : _random = random ?? Random();

  final Random _random;

  // Riverpod memanggil build saat provider pertama kali dibaca atau di-invalidate.
  @override
  Future<List<Statistic>> build() => _fetchStatistics();

  // Tombol retry memanggil method ini melalui ref.read di halaman.
  void retry() => ref.invalidateSelf();

  // Simulasi request jaringan dengan delay dan peluang gagal sebesar 30 persen.
  Future<List<Statistic>> _fetchStatistics() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (_random.nextDouble() < 0.3) {
      throw Exception('Gagal mengambil data statistik');
    }

    // List baru dikembalikan setiap request sehingga data tidak dimutasi langsung.
    return const [
      Statistic(label: 'Pengguna aktif', value: 1280),
      Statistic(label: 'Pesanan selesai', value: 342),
      Statistic(label: 'Pendapatan hari ini', value: 8750000),
    ];
  }
}

// Provider diberi tipe lengkap dan menjadi satu-satunya provider untuk statistik.
final AsyncNotifierProvider<StatsNotifier, List<Statistic>> statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<Statistic>>(StatsNotifier.new);
