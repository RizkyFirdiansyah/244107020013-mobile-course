# Week 4 - REST API Refactoring

Project ini menggunakan JSONPlaceholder melalui repository, Dio client
terpusat, dan Riverpod.

## Perubahan refactoring

- [`PostTile`](lib/widgets/post_tile.dart) mengekstrak baris post yang dapat
  digunakan halaman list biasa maupun pagination. Tile menerima callback
  `onTap` untuk navigasi ke detail.
- [`network_errors.dart`](lib/data/network_errors.dart) menjadi satu sumber
  `friendlyErrorMessage` untuk halaman paged, non-paged, detail, dan provider
  lain.
- [`router.dart`](lib/router.dart) memakai GoRouter dengan route `/` dan
  `/post/:id`.
- [`PostDetailPage`](lib/pages/post_detail_page.dart) menampilkan `title` dan
  `body` lengkap. `postDetailProvider` mencari post yang sudah dimuat di state
  pagination terlebih dahulu, lalu memanggil `PostRepository.fetchPost` bila
  post belum tersedia, termasuk saat route detail dibuka langsung.
- Akses HTTP tetap berada di repository. Widget hanya berkomunikasi dengan
  provider dan tidak membuat atau memanggil Dio secara langsung.

## Perilaku state

| Area | Loading | Error | Empty | Success |
|---|---|---|---|---|
| Post list | `CircularProgressIndicator` | pesan ramah + tombol coba lagi | pesan data kosong | daftar `PostTile` |
| Pagination | indikator di bagian bawah | pesan ramah + tombol coba lagi saat halaman pertama gagal | daftar kosong dengan state awal | item bertambah saat scroll, lalu `Semua data termuat.` |
| Detail post | `CircularProgressIndicator` | pesan ramah + tombol coba lagi | tidak berlaku untuk satu post | title dan body lengkap |

Pagination mencegah request ganda dengan guard `isLoadingMore` dan berhenti
ketika response terakhir berisi kurang dari limit. Detail post menggunakan
provider family sehingga setiap `id` mempunyai state sendiri.

## Hasil verifikasi

- **UI tidak memanggil Dio langsung:** terverifikasi. Pemanggilan HTTP hanya
  ada di `api_client.dart` dan repository; UI memakai provider.
- **Empat state:** halaman non-paged, paged, dan detail memiliki cabang
  loading/error/empty atau success yang sesuai. Error menyediakan retry.
- **Pagination:** `loadNextPage` mengembalikan lebih awal saat sedang memuat
  atau data sudah habis; indikator akhir ditampilkan.
- **Detail route:** `/post/:id` memakai data pagination yang sudah tersedia,
  dengan fallback ke `fetchPost(id)` untuk deep link.
- **`flutter analyze`:** berhasil tanpa issue.
- **`flutter test`:** seluruh test berhasil.

Perintah verifikasi:

```text
flutter analyze --no-pub
No issues found!

flutter test
All tests passed!
```
