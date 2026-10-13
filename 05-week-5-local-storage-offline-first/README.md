# Laporan Praktikum Mingguan: Minggu 05 - Local Storage & Offline-First Architecture

## 1. Tujuan

- Menjelaskan perbedaan penyimpanan key-value, relasional, dan NoSQL di perangkat.
- Menyimpan preferensi sederhana (tema, terakhir dibuka) dengan `SharedPreferences`.
- Menerapkan CRUD catatan dengan SQLite (`sqflite`) melalui repository lokal.
- Menerapkan pola offline-first: cache-first read, dirty flag, dan antrean sinkronisasi.
- Menampilkan state loading, error, empty, dan success untuk data lokal dengan Riverpod.
- Menguji repository lokal dengan repository palsu tanpa database sungguhan.

---

## 2. Langkah Praktikum

### Inisialisasi Project & Dependensi

Project dibuat langsung di dalam folder `05-week-5-local-storage-offline-first/` dengan nama package `week5_offline_notes`, tanpa mengubah nama folder.

Perintah inisialisasi dan instalasi dependensi:

```bash
flutter create --project-name week5_offline_notes --org com.example .
flutter pub add flutter_riverpod shared_preferences sqflite path
```

Dependensi utama:

- `flutter_riverpod: ^3.4.3` (manajemen state reaktif dan `AsyncValue`).
- `shared_preferences: ^2.5.6` (penyimpanan key-value untuk preferensi).
- `sqflite: ^2.4.4+1` (database relasional lokal untuk catatan).
- `path: ^1.9.1` (penyusunan path database).
- `go_router: ^18.0.2` (navigasi deklaratif untuk rute detail `/note/:id`).

Struktur folder kerja:

```text
05-week-5-local-storage-offline-first/
├── docs/
│   └── ai_challenge.md
├── lib/
│   ├── main.dart
│   ├── data/
│   │   ├── api_client.dart
│   │   ├── prefs.dart
│   │   ├── sync.dart
│   │   ├── local/
│   │   │   ├── db.dart
│   │   │   └── note.dart
│   │   ├── models/
│   │   │   └── post.dart
│   │   └── repositories/
│   │       └── note_repository.dart
│   ├── pages/
│   │   ├── note_detail_page.dart
│   │   ├── notes_page.dart
│   │   ├── posts_page.dart
│   │   └── settings_page.dart
│   ├── utils/
│   │   └── date_format.dart
│   └── widgets/
│       ├── note_tile.dart
│       └── offline_toggle.dart
├── test/
│   └── note_test.dart
├── screenshots/
└── README.md
```

---

## 3. Implementasi Fitur & AI Challenge

### Praktikum 1: Preferensi dengan SharedPreferences

1. **Repository Preferensi (`lib/data/prefs.dart`)**
   - `PrefsRepository` memusatkan seluruh akses key-value `SharedPreferences` pada satu tempat, bukan tersebar di widget.
   - Menyediakan `getDarkMode`/`setDarkMode` (kunci `dark_mode`) serta `markOpenedNow`/`getLastOpened` (kunci `last_opened_at`).

2. **Provider & Notifier Tema (`lib/pages/settings_page.dart`)**
   - `prefsRepositoryProvider` menyediakan instance `PrefsRepository`.
   - `darkModeProvider` (`AsyncNotifierProvider<DarkModeNotifier, bool>`) membaca preferensi tema secara asinkron melalui `DarkModeNotifier.build()`.
   - Method `toggle()` membalik nilai tema dan menyimpannya dengan pola `AsyncValue.guard`.

   > Catatan: kode `prefs.dart` dan provider/notifier disalin persis dari modul. Karena modul tidak menyertakan widget halaman, file `settings_page.dart` masih memicu warning `unused_import` (import `material.dart` belum terpakai) dan warning ini sengaja dipertahankan sesuai keputusan.

### Praktikum 2: SQLite dan Repository Catatan

1. **Model Catatan (`lib/data/local/note.dart`)**
   - Kelas `Note` dengan field `id`, `title`, `body`, `updatedAt`, dan `dirty`.
   - `toMap()`/`fromMap()` defensif null; field `dirty` disimpan sebagai integer (`1`/`0`) sebagai penanda antrean sinkronisasi.

2. **Pembuka Database (`lib/data/local/db.dart`)**
   - Fungsi tunggal `openNotesDb()` dipakai seluruh repository.
   - Membuat dua tabel pada `onCreate`: `notes` (id autoincrement, title, body, updated_at, dirty) dan `cached_posts` (id, payload, cached_at).

3. **Repository Catatan (`lib/data/repositories/note_repository.dart`)**
   - Constructor menerima `openDb` opsional agar test dapat menyuntikkan database palsu/in-memory tanpa menyentuh SQLite sungguhan.
   - Menyediakan `fetchNotes` (urut `updated_at DESC`), `addNote` (otomatis `dirty: true`), `deleteNote`, `countDirty`, dan `markAllSynced`.

### Praktikum 3: Cache-First & Antrean Sinkronisasi

1. **Dukungan Jaringan & Model Post** (`lib/data/api_client.dart`, `lib/data/models/post.dart`)
   - Menambahkan dependensi `dio` dan model `Post` (dipakai ulang dari Minggu 4) karena `loadPostsCacheFirst` mengembalikan `List<Post>` dan memakai Dio.
   - `createDio()` mengonfigurasi base URL JSONPlaceholder, timeout, dan `LogInterceptor`.

2. **Logika Cache-First & Sinkronisasi** (`lib/data/sync.dart`)
   - `readCachedPosts()` membaca tabel `cached_posts` dan memetakannya kembali menjadi `Post`.
   - `saveCachedPosts()` menyimpan hasil fetch ke cache (upsert per `id`).
   - `PostsCacheNotifier` mengimplementasikan alur cache-first: `loadPostsCacheFirst()` mengembalikan cache seketika lalu memanggil `refreshPostsInBackground()`; jika gagal/offline, cache lama tetap tampil.
   - `syncNotes(NoteRepository)` menghitung `countDirty`, mensimulasikan upload dengan delay, lalu memanggil `markAllSynced`.

3. **Toggle Simulasi Offline** (`lib/data/sync.dart`)
   - `forceOfflineProvider` (`NotifierProvider<ForceOfflineNotifier, bool>`) menyediakan toggle deterministik agar demo/testing tidak bergantung pada kondisi Wi-Fi; saat aktif, `refreshPostsInBackground()` berhenti lebih awal.

### Halaman Aplikasi

1. **Halaman Catatan (`lib/pages/notes_page.dart`)**
   - Menampilkan daftar catatan dari `notesProvider` (repository lokal) dengan empat state: loading, error, empty, dan success.
   - Tambah catatan lewat `AlertDialog` (judul + isi), hapus dengan konfirmasi, dan pull-to-refresh.
   - Banner "`N catatan belum tersinkron.`" muncul saat ada catatan `dirty`, dan tombol sinkron memanggil `syncNotes` lalu menampilkan `SnackBar`.

2. **Halaman Posts Cache (`lib/pages/posts_page.dart`)**
   - Menampilkan hasil cache-first dari `postsCacheProvider`; tombol refresh memicu `refreshPostsInBackground()`.

3. **Halaman Pengaturan (`lib/pages/settings_page.dart`)**
   - `SettingsPage` memakai `darkModeProvider` untuk toggle tema gelap/terang dan `lastOpenedProvider` untuk menampilkan waktu terakhir dibuka.
   - Nilai waktu diformat lewat helper `formatDateTime` (`lib/utils/date_format.dart`) yang mengonversi nilai ke waktu lokal (dari UTC bila ada) menjadi format ramah baca, misalnya `09 Okt 2026, 18:26`.

4. **Navigasi (`lib/main.dart`)**
   - `MaterialApp.router` dengan `GoRouter` (`StatefulShellRoute.indexedStack`) untuk berpindah antara Catatan, Posts Cache, dan Pengaturan, plus rute detail `/note/:id`.
   - `MyApp` (sebagai `ConsumerWidget`) menyinkronkan `themeMode` dengan `darkModeProvider`, sehingga toggle tema langsung mengubah tampilan aplikasi.

5. **Provider (`lib/data/repositories/note_repository.dart`)**
   - `noteRepositoryProvider` dan `notesProvider` diletakkan di file repository agar dapat diimpor oleh `test/note_test.dart` sesuai modul.
   - `noteByIdProvider` (`FutureProvider.family<Note?, int>`) menyediakan detail catatan per id.

### Refactoring Challenge & Testing

1. **Ekstraksi `NoteTile` (`lib/widgets/note_tile.dart`)**
   - Baris catatan dijadikan widget terpisah `NoteTile` yang menampilkan badge "belum tersinkron" bila `note.dirty == true`.

2. **Pemisahan Logika Sync (`lib/data/sync.dart`)**
   - Cache posts (`readCachedPosts`, `saveCachedPosts`, `PostsCacheNotifier`) dan `syncNotes` ditempatkan di `sync.dart` agar `NoteRepository` tetap fokus pada CRUD.

3. **Halaman Detail Catatan (`lib/pages/note_detail_page.dart`)**
   - Rute `/note/:id` dibangun dengan `GoRouter` dan membaca data langsung dari repository lokal melalui `noteByIdProvider` (bukan dari state halaman list).

4. **Pengujian (`test/note_test.dart`)**
   - Unit test model (`fromMap` aman null, dirty bertahan pada serialisasi) dan test provider dengan `FakeNoteRepository` (sukses & error) tanpa menyentuh SQLite sungguhan.
   - Hasil: `flutter analyze` tanpa issue fatal dan `flutter test` lulus 4/4.

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

### Bukti Visual Implementasi (Screenshots)

| Bukti Tampilan | Deskripsi Antarmuka |
| :---: | :--- |
| ![Catatan Offline](./screenshot/before-singkron.png) | **Daftar Catatan (Mode Pesawat)**: catatan tetap tampil walau tanpa internet karena bersumber dari SQLite lokal. |
| ![Badge Sebelum Sync](./screenshot/after-singkron.png) | **Badge Dirty Sebelum Sync**: banner menampilkan jumlah catatan yang belum tersinkron. |
| ![Badge Sesudah Sync](./screenshot/after-singkron.png) | **Badge Dirty Sesudah Sync**: setelah `syncNotes`, badge kembali bersih (0). |
| ![Detail Catatan](./screenshot/detail.png) | **Detail Catatan (`/note/:id`)**: dibuka via GoRouter dan membaca data langsung dari repository lokal; tanggal tampil terformat waktu lokal. |
| ![Hasil Flutter Analyze dan Test](./screenshot/test.png) | **Hasil `flutter analyze` dan `flutter test`**: `flutter analyze` berhasil tanpa issue, sedangkan `flutter test` berhasil dengan seluruh test lulus (`All tests passed!`). |

> Catatan: screenshot di atas diambil langsung dari aplikasi yang berjalan pada emulator Android (720×1280). Banner `DEBUG` muncul karena dijalankan dalam mode debug.

### AI Challenge

Perbandingan storage (SharedPreferences, Hive, sqflite, Drift), rekomendasi final, skema 1000+ catatan, dan checklist verifikasi AI terdokumentasi pada [bagian AI Challenge](#perbandingan-pilihan-penyimpanan).

---

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

## 4. Refleksi

1. **Mengapa Daftar Catatan Tidak Boleh Disimpan di SharedPreferences dan Dampak Pelanggarannya**:
   - SharedPreferences hanya dirancang untuk nilai primitif kecil (tema, bahasa, waktu terakhir dibuka), bukan koleksi data.
   - Jika daftar catatan disimpan sebagai satu string JSON, setiap tambah/hapus menuntut baca-tulis seluruh daftar, tidak ada query parsial (urut/filter), dan sinkronisasi menjadi lambat serta rawan korup saat data bertambah.

2. **Kapan Cache-First Cukup dan Kapan Butuh Strategi Lain**:
   - Cache-first cukup untuk data yang jarang berubah dan toleran tampil sedikit lama (daftar catatan, artikel), sehingga UI tampil instan tanpa menunggu jaringan.
   - Strategi lain (network-first) diperlukan saat data harus selalu segar seperti harga real-time atau saldo, karena menampilkan cache lama berisiko menyesatkan pengguna.

3. **Bagaimana Dirty Flag Menjadi Antrean Sync Tanpa Memblokir UI dan Kapan Outbox Perlu**:
   - Perubahan lokal hanya menandai `dirty = 1` dan langsung selesai dari sisi UI; proses kirim ke server berjalan terpisah (`syncNotes`) lalu `markAllSynced`, sehingga UI tidak menunggu jaringan.
   - Tabel outbox terpisah menjadi perlu saat tiap operasi harus dikirim berurutan dengan penanganan gagal/retry per-operasi, bukan sekadar penanda status pada catatan.

4. **Bagian Rekomendasi AI yang Ditolak dan Alasannya**:
   - Rekomendasi memakai Drift/Hive untuk catatan ditolak karena menambah kompleksitas (codegen/`build_runner`, adapter) tanpa manfaat nyata untuk kebutuhan CRUD + antrean sync sederhana.
   - Klaim "real-time" tanpa dukungan stream juga ditolak; reaktivitas hanya sah bila didukung `watch` (Drift) atau `ref.invalidate` (Riverpod).

---

## 5. Jurnal Belajar

### Ringkasan Teknis

- **Pemilihan Storage Sesuai Kebutuhan**: SharedPreferences untuk preferensi key-value kecil, SQLite (`sqflite`) untuk catatan yang butuh query terurut dan update parsial.
- **Repository Preferensi Terpusat**: `PrefsRepository` memusatkan akses key-value dan disambungkan ke `darkModeProvider` (`AsyncNotifier`).
- **CRUD Lokal dengan Penanda Sinkronisasi**: Model `Note` menyimpan `dirty` dan `updated_at`, sedangkan `NoteRepository` (dengan injeksi `openDb`) menangani CRUD, `countDirty`, dan `markAllSynced`.
- **Pola Offline-First**: Cache-first read menampilkan cache lokal lebih dulu lalu refresh di background; dirty flag + `syncNotes` menangani antrean tulisan; aturan konflik *last-write-wins* berbasis `updated_at`.
- **State Lokal dengan Riverpod**: `AsyncNotifier`/`AsyncValue` menampilkan empat state (loading, error, empty, success) untuk data lokal.
- **Preferensi Tema & Format Waktu Lokal**: Halaman `SettingsPage` membaca `darkModeProvider` dan `lastOpenedProvider`; helper `formatDateTime` mengubah nilai waktu ke zona lokal dengan format `09 Okt 2026, 18:26`.
- **Pengujian Terisolasi**: `FakeNoteRepository` menguji provider tanpa menyentuh SQLite sungguhan.

### Kendala

1. **`databaseFactory not initialized` saat dijalankan di desktop**: `sqflite` hanya menginisialisasi factory otomatis di Android/iOS, sehingga gagal di macOS. **Solusi**: menjalankan aplikasi pada emulator Android.
2. **`TextEditingController was used after being disposed`**: controller dibuang tepat setelah `showDialog` selesai, sementara animasi keluar masih me-rebuild `TextField`. **Solusi**: memindahkan kepemilikan controller ke `StatefulWidget` dialog yang membuangnya di `dispose()`.
3. **Warning `unused_import` pada `settings_page.dart`**: kode modul hanya berisi provider/notifier tanpa widget halaman. **Solusi**: menambahkan widget `SettingsPage` pada file yang sama sehingga import `material.dart` terpakai dan warning hilang.
4. **Waktu mentah berformat ISO8601**: nilai `updated_at`/`last_opened_at` awalnya tampil sebagai string ISO mentah. **Solusi**: helper `formatDateTime` mengonversi ke waktu lokal dan memformatnya menjadi `09 Okt 2026, 18:26`.

---

## 6. Kesimpulan

Seluruh materi Minggu 05 terselesaikan: preferensi `SharedPreferences`, CRUD catatan SQLite melalui repository lokal, pola offline-first (cache-first, dirty flag, dan antrean sinkronisasi), empat state lokal dengan Riverpod, halaman detail `GoRouter`, halaman pengaturan tema dengan format waktu lokal, serta pengujian dengan repository palsu. Analisis statis bersih tanpa warning dan seluruh 4 tes lulus.
