# Verifikasi StatsPage

## Hasil pemeriksaan

- **State immutable:** Ya. `StatsNotifier` selalu mengembalikan list baru dari
  request dan tidak menggunakan `state.add()` atau mutasi list langsung.
- **`ref.watch` dan `ref.read`:** Ya. `ref.watch(statsProvider)` hanya berada di
  `build`. Callback retry menggunakan `ref.read`.
- **Tiga `AsyncValue`:** Ya. `StatsPage` menangani `loading` dengan spinner,
  `error` dengan pesan dan tombol retry, serta `data` dengan `ListView` tiga item.
- **Provider eksplisit dan tidak duplikat:** Ya. Provider dideklarasikan sebagai
  `AsyncNotifierProvider<StatsNotifier, List<Statistic>> statsProvider` dan tidak
  ada provider statistik lain.
- **API Riverpod:** Ya. Implementasi menggunakan `AsyncNotifier` dan
  `ConsumerWidget`, tanpa `StateProvider`, `StateNotifierProvider`, atau
  `Consumer` bertingkat yang tidak perlu.

## Validasi

- `flutter analyze`: **lulus**, `No issues found!`.
- `flutter test`: **lulus**, `00:06 +3: All tests passed!`.
- Hot restart: DTD berhasil ditemukan dan tersambung, tetapi tidak ada aplikasi
  Flutter aktif yang dapat di-hot-restart.
