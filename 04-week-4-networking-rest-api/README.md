# Week 4 - Repository Layer Comments

Implementasi ini mengambil komentar JSONPlaceholder melalui:

`GET https://jsonplaceholder.typicode.com/comments?postId={id}`

## Struktur kode

- `lib/data/api_client.dart` membuat satu instance `Dio` dengan `baseUrl`,
  header JSON, dan timeout koneksi/penerimaan 10 detik.
- `lib/data/models/comment.dart` berisi model `Comment`. `fromJson` memeriksa
  tipe nilai sebelum mengonversi angka dan memakai nilai default untuk field
  yang hilang atau `null`.
- `lib/data/repositories/comment_repository.dart` berisi satu-satunya kode
  yang memanggil endpoint comments. Repository menerima `Dio` melalui
  dependency injection dan meneruskan `postId` sebagai query parameter.
- `lib/data/providers.dart` menyediakan `commentRepositoryProvider` dan
  `commentsProvider`, sebuah `AsyncNotifierProvider.family`. Exception dari
  repository otomatis menjadi `AsyncError`; `friendlyErrorMessage` mengubah
  error jaringan menjadi pesan yang dapat dipahami pengguna.
- `test/comment_model_test.dart` menguji parsing normal, field yang hilang,
  object JSON kosong, nilai `null`, konversi angka, dan ketidaksesuaian tipe.

## Hasil verifikasi

| Checklist | Hasil |
|---|---|
| UI memanggil Dio langsung? | Tidak. UI memakai provider, provider memakai `CommentRepository`, dan repository memakai `Dio`. |
| `fromJson` aman untuk `null` dan field hilang? | Ya. Semua field memiliki fallback (`0` atau string kosong), dan tipe numeric/string diperiksa sebelum cast. |
| Semua tipe timeout dipetakan? | Ya. `connectionTimeout`, `sendTimeout`, dan `receiveTimeout` menghasilkan pesan timeout. |
| `connectionError` dipetakan? | Ya. Pesan meminta pengguna memeriksa koneksi internet. |
| `badResponse` 404 dan 500 dipetakan? | Ya. 404 menghasilkan pesan data tidak ditemukan; 500 dan status server lain menghasilkan pesan server bermasalah. |
| `baseUrl` dan timeout terpusat? | Ya. Konfigurasi utama berada di `createDio()`; repository juga menetapkan batas `sendTimeout` dan `receiveTimeout` 10 detik untuk request comments. |
| Test benar-benar menguji field hilang? | Ya. Test mencakup field hilang satu per satu dan object JSON kosong, serta edge case tipe salah. |
| `flutter analyze` | Berhasil tanpa warning/error setelah perbaikan parsing dan import. |
| `flutter test` | Unit test model Comment berhasil dijalankan dan memverifikasi seluruh kasus di atas. |

## Contoh penggunaan provider

```dart
final comments = ref.watch(commentsProvider(postId));

return comments.when(
  loading: () => const CircularProgressIndicator(),
  error: (error, _) => Text(friendlyErrorMessage(error)),
  data: (items) => ListView(
    children: items.map((comment) => Text(comment.body)).toList(),
  ),
);
```
