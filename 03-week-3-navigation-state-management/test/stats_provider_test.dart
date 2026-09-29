import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week3_navigation/providers/stats_provider.dart';

// Random deterministik untuk memaksa cabang sukses atau gagal tanpa flakiness.
class FixedRandom implements Random {
  FixedRandom(this.value);

  final double value;

  @override
  bool nextBool() => value >= 0.5;

  @override
  double nextDouble() => value;

  @override
  int nextInt(int max) => (value * max).floor();
}

void main() {
  test('notifier mengembalikan tiga statistik saat request berhasil', () async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        statsProvider.overrideWith(
          () => StatsNotifier(random: FixedRandom(0.5)),
        ),
      ],
    );
    addTearDown(container.dispose);

    final statistics = await container.read(statsProvider.future);

    expect(statistics, hasLength(3));
    expect(statistics.first.label, 'Pengguna aktif');
  });

  test('notifier menghasilkan error saat request gagal', () async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        statsProvider.overrideWith(
          () => StatsNotifier(random: FixedRandom(0.2)),
        ),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(container.read(statsProvider.future), throwsException);
  });
}
