# Praktikum 3 - Offline Notes

Aplikasi Flutter ini mendemonstrasikan CRUD catatan, preferensi tema, cache-first
untuk `GET /posts`, dan antrean sinkronisasi catatan dirty.

## Hasil Refactoring Challenge

### `NoteTile`

Baris catatan diekstrak ke [note_tile.dart](lib/widgets/note_tile.dart). Widget ini:

- menerima model `Note`, sehingga tidak membuka database sendiri;
- menampilkan chip **Belum tersinkron** ketika `note.dirty == true`;
- menyediakan aksi hapus melalui callback dari halaman;
- membuka detail melalui route `/note/:id`.

Dengan begitu, UI tetap hanya berkomunikasi dengan provider/repository melalui callback,
bukan memanggil SQLite atau SharedPreferences secara langsung.

### Pemisahan sinkronisasi

Logika cache posts dan `syncNotes()` berada di
[sync.dart](lib/data/sync.dart). `NoteRepository` tetap berfokus pada CRUD dan query
catatan (`fetchNotes`, `fetchNoteById`, `addNote`, `deleteNote`, `countDirty`, dan
`markAllSynced`). Fungsi `syncNotes` menerima repository sebagai dependency sehingga
mudah diuji dan tidak mengikat UI ke database.

### Detail catatan dengan GoRouter

Router pada [main.dart](lib/main.dart) menyediakan:

```text
/       -> HomePage
/note/:id -> NoteDetailPage
```

`NoteDetailPage` mengambil ulang catatan melalui `noteDetailProvider`, yang memanggil
`NoteRepository.fetchNoteById(id)`. Detail tidak membaca item dari state list, sehingga
route tetap benar setelah restart, refresh, atau navigasi langsung ke URL.

### Verifikasi checklist refactoring

| Checklist | Hasil verifikasi |
|---|---|
| UI tidak memanggil SQLite/SharedPreferences langsung | **Lulus.** UI memakai `notesProvider`, `noteDetailProvider`, `noteRepositoryProvider`, dan callback repository. |
| Baca, tambah, hapus dalam mode pesawat | **Lulus secara desain.** Semua operasi catatan memakai SQLite lokal; network hanya digunakan untuk refresh posts dan tidak diperlukan untuk CRUD catatan. |
| Badge dirty akurat sebelum/sesudah sync | **Lulus.** `dirtyNotesCountProvider` memakai `COUNT(*) WHERE dirty = 1`, di-invalidate setelah tambah, hapus, dan sync. `NoteTile` menampilkan chip berdasarkan `note.dirty`. |
| Cache posts tanpa internet | **Lulus secara desain.** Posts dibaca dari `cached_posts`; refresh Dio berjalan di background dan kegagalan jaringan mempertahankan cache. `forceOffline` dapat dipakai untuk demo deterministik. |
| GoRouter detail membaca repository | **Lulus.** `/note/:id` memakai `fetchNoteById`, bukan state list. |
| `flutter analyze` tanpa issue | **Lulus.** Tidak ada issue setelah refactoring. |
| Semua test lulus | **Lulus.** Widget test berhasil dijalankan. |

## Perbandingan pilihan penyimpanan

| Pilihan | Kompleksitas query | Relasi | Reaktivitas | Type-safety | Boilerplate | Testing | Keputusan untuk aplikasi ini |
|---|---|---|---|---|---|---|---|
| **SharedPreferences** | Sangat rendah; key-value saja | Tidak cocok | Tidak menyediakan query/stream database | Rendah; nilai dibatasi tipe primitif dan list string | Paling kecil | Mudah, tetapi perlu mock key-value | **Preferensi tema** |
| **Hive** | Rendah; box/key-value, filter kompleks harus di kode | Terbatas; relasi manual | `ValueListenable`/listener tersedia, tetapi bukan stream SQL | Baik jika memakai adapter generator; tanpa adapter masih dinamis | Rendah-menengah; box, adapter, dan registrasi | Cukup mudah dengan box in-memory | Alternatif untuk catatan sederhana tanpa relasi |
| **sqflite (SQLite)** | Tinggi; SQL, index, transaksi, agregasi | Baik; foreign key dan join tersedia | Tidak built-in; perlu `Stream`, invalidasi provider, atau polling | Sedang-rendah; row berupa `Map`, model/mapper dibuat manual | Menengah; SQL, migrasi, mapper, factory platform | Baik; repository dapat diuji dengan database in-memory/mock | **Catatan untuk praktikum ini** |
| **Drift** | Tinggi; SQL dengan API Dart dan query terstruktur | Sangat baik; foreign key, join, migrasi | **Baik; `watch()` menghasilkan stream** | **Paling kuat**; tabel dan query diketik/generate | Menengah-tinggi; generator, database class, migrasi | Sangat baik; native/in-memory test database | Rekomendasi jika aplikasi berkembang dan butuh stream/type-safety |

### Rekomendasi final

| Kebutuhan | Pilihan | Alasan |
|---|---|---|
| Preferensi tema (`darkMode`) | **SharedPreferences** | Hanya membutuhkan satu nilai boolean, tidak membutuhkan query, relasi, transaksi, atau stream. |
| Catatan 1000+ item dan antrean sync | **sqflite untuk praktikum ini** | Sudah terpasang, API SQL cukup untuk CRUD dan query dirty, serta mudah menunjukkan `dirty` dan `updated_at`. |
| Catatan pada aplikasi produksi yang membutuhkan UI real-time | **Drift** | `watch()`/stream, generated types, query relasional, dan migrasi lebih aman ketika fitur bertambah. |

SharedPreferences **tidak digunakan untuk daftar catatan**. Menyimpan seluruh daftar sebagai
JSON/string memang mungkin, tetapi rapuh: seluruh koleksi harus dibaca dan ditulis ulang,
tidak ada query/index/transaksi per baris, dan risiko korupsi atau konflik data lebih besar.

## Skema catatan untuk 1000+ data

Skema yang digunakan aplikasi saat ini:

```text
+---------------------+
| notes               |
+---------------------+
| id          INTEGER | PK, AUTOINCREMENT
| title       TEXT    | NOT NULL
| body        TEXT    | NOT NULL, default ''
| updated_at  TEXT    | NOT NULL, ISO-8601
| dirty       INTEGER | NOT NULL, 0 atau 1
+---------------------+
```

Indeks yang disarankan ketika jumlah data dan query bertambah:

```sql
CREATE INDEX idx_notes_updated_at ON notes(updated_at DESC);
CREATE INDEX idx_notes_dirty_updated_at
  ON notes(dirty, updated_at DESC);
```

Contoh query antrean sinkronisasi:

```sql
SELECT id, title, body, updated_at
FROM notes
WHERE dirty = 1
ORDER BY updated_at ASC
LIMIT 50;
```

`dirty = 1` menandai catatan yang belum berhasil dikirim ke server. `updated_at` dipakai
untuk urutan antrean dan resolusi konflik sederhana. Pada implementasi praktikum,
`syncNotes()` menghitung baris dirty, menunggu satu detik sebagai simulasi upload, lalu
memanggil `markAllSynced()`. Backend nyata seharusnya mengirim per catatan dan hanya
mengubah baris menjadi bersih setelah respons HTTP 2xx.

Untuk sinkronisasi yang lebih kuat, skema dapat diperluas menjadi:

```text
+-----------------------------+       +----------------------+
| notes                       |       | sync_queue           |
+-----------------------------+       +----------------------+
| id PK                       |       | id PK                |
| title, body                 |       | note_id FK -> notes  |
| updated_at                  |       | operation            |
| dirty                       |       | attempts             |
| server_version (optional)   |       | last_error           |
+-----------------------------+       | next_retry_at        |
                                     +----------------------+
```

Namun, untuk requirement praktikum, kolom `dirty` dan `updated_at` sudah cukup untuk
menunjukkan mekanisme antrean sync.

## Verifikasi checklist

### 1. Apakah daftar catatan ditempatkan di SharedPreferences?

**Tidak.** Preferensi tema menggunakan `SharedPreferences`, sedangkan daftar catatan dan
status dirty disimpan di tabel SQLite `notes`. Ini tepat untuk koleksi karena catatan dapat
di-query per baris dan tidak perlu serialisasi seluruh daftar.

### 2. Apakah skema mendukung antrean sync?

**Ya.** Tabel memiliki:

- `dirty`: status belum tersinkronisasi;
- `updated_at`: urutan perubahan;
- `countDirty()`: menghitung antrean;
- `markAllSynced()`: menandai data selesai;
- counting badge pada tombol sinkronisasi.

### 3. Apakah klaim real-time didukung stream?

**Belum pada implementasi saat ini.** `notesProvider` dan `dirtyNotesCountProvider`
menggunakan `FutureProvider`, kemudian di-refresh dengan `ref.invalidate()`. Itu adalah
refresh terkontrol, bukan real-time stream.

Jika memakai Drift, bentuk real-time yang benar adalah:

```dart
Stream<List<Note>> watchNotes() => select(notes).watch();
```

Lalu UI memakai `StreamProvider`, sehingga perubahan database memicu pembaruan otomatis.
Hive dapat memakai `box.listenable()`/listener, tetapi itu berbeda dari stream query
relasional Drift.

### 4. Apakah estimasi boilerplate masuk akal?

Verifikasi terhadap proyek saat ini:

- `shared_preferences`, `sqflite`, `sqflite_common_ffi`, dan
  `sqflite_common_ffi_web` memang tercantum di `pubspec.yaml`;
- SQLite membutuhkan kode factory platform, tabel, model `Note`, repository, serta query
  dirty;
- Hive dan Drift **belum dipasang atau dipakai** pada proyek ini, sehingga estimasi
  boilerplate keduanya adalah perbandingan desain, bukan klaim hasil implementasi lokal;
- instalasi paket yang sudah digunakan diverifikasi dengan `flutter pub get`, lalu
  `flutter analyze` dan `flutter test` berhasil.

Perintah awal untuk eksperimen terpisah:

```powershell
flutter pub add hive hive_flutter
flutter pub add drift drift_flutter
```

Drift juga memerlukan konfigurasi generator (`build_runner`) dan file database/tabel.
Karena praktikum ini sudah berjalan dengan SQLite langsung, menambahkan kedua alternatif
tersebut tidak diperlukan untuk fitur yang dinilai.

### 5. Keputusan akhir

Keputusan akhir adalah:

1. **SharedPreferences untuk preferensi tema**, karena datanya kecil, sederhana, dan
   berbentuk key-value.
2. **sqflite untuk catatan pada praktikum ini**, karena sudah terintegrasi dan secara jelas
   memperlihatkan SQL, CRUD, cache lokal, `dirty`, `updated_at`, serta migrasi dasar.
3. **Drift sebagai pilihan upgrade produksi**, jika kebutuhan stream real-time, relasi,
   type-safety, dan migrasi bertambah.
4. **Hive bukan pilihan utama untuk requirement ini**, meskipun cukup baik untuk koleksi
   lokal sederhana; kebutuhan query SQL dan antrean sync lebih mudah dijelaskan dengan
   SQLite.

## Validasi

```text
flutter analyze
No issues found!

flutter test
All tests passed!
```
