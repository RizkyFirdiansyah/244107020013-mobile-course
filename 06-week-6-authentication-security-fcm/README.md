# campus_notify

## Praktikum 3: Payload, tiga app state, klik dan topik

### Background handler

Handler FCM harus berupa fungsi top-level karena dijalankan pada isolate
terpisah. Handler hanya melakukan inisialisasi ringan; navigasi dilakukan
setelah notifikasi diklik.

### Payload gabungan

Gunakan payload FCM HTTP v1 berikut untuk pengujian:

```json
{
  "message": {
    "topic": "pengumuman-kampus",
    "notification": {
      "title": "Jadwal kuliah berubah",
      "body": "Kelas Mobile pindah ke Ruang A2 jam 13.00"
    },
    "data": {
      "route": "/pengumuman/3",
      "id": "3"
    }
  }
}
```

Kode aplikasi menangani tiga keadaan:

- **Foreground:** `onMessage` menampilkan local notification. Klik notifikasi
  menyimpan `route` untuk diproses router.
- **Background:** sistem menampilkan notification payload. Klik ditangani oleh
  `onMessageOpenedApp`.
- **Terminated:** `getInitialMessage` mengambil pesan yang membuka aplikasi.

### Matriks pengujian

| State | Yang diharapkan | Cara uji |
|---|---|---|
| Foreground | Banner lokal muncul, klik masuk ke `/pengumuman/3` | Aplikasi terbuka, kirim payload dari Firebase Console/backend |
| Background | Banner sistem muncul, klik masuk ke rute yang benar | Tekan Home, kirim payload, lalu klik banner |
| Terminated | Aplikasi terbuka ke rute yang benar melalui `getInitialMessage` | Swipe-close aplikasi, kirim payload, lalu klik banner |

### Topic messaging

Aplikasi otomatis berlangganan topic berikut saat mendapatkan token:

```dart
await FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');
```

Untuk berhenti berlangganan:

```dart
await FirebaseMessaging.instance
    .unsubscribeFromTopic('pengumuman-kampus');
```

Nama topic tidak boleh mengandung spasi dan cocok untuk broadcast, misalnya
semua mahasiswa, satu kelas, atau satu UKM. Untuk pesan personal seperti nilai
atau tagihan, gunakan token perangkat, bukan topic.

Pesan yang berisi `notification` ditampilkan otomatis oleh sistem saat aplikasi
background/terminated. Pesan data-only tidak ditampilkan otomatis dan pada
Android harus diproses manual.

## Verifikasi AI terhadap checklist

Verifikasi berikut dilakukan terhadap class `PushService` pada
`lib/messaging/push_service.dart` dan integrasinya pada `lib/main.dart`.

| Checklist | Status | Bukti/verifikasi |
|---|---|---|
| Background handler top-level dengan `@pragma('vm:entry-point')` | LULUS | `firebaseMessagingBackgroundHandler` adalah fungsi top-level dan tidak mengakses `BuildContext`, Riverpod, atau router. |
| `onTokenRefresh` mengirim token baru ke backend | LULUS | `PushService.initialize` mendaftarkan `onTokenRefresh.listen(onToken)`, lalu callback integrasi `main` mengirim `POST /devices` dengan `fcm_token` dan `platform`. |
| Foreground memakai local notification manual | LULUS | `PushService.initialize` mendaftarkan listener `onMessage`, lalu `_showForegroundNotification` memanggil `_local.show` dengan payload route. |
| Klik foreground menuju route yang benar | LULUS SECARA KODE | Callback `onDidReceiveNotificationResponse` menyimpan `data.route` sebagai `pendingDeepLink`; router memproses route tersebut. |
| Klik background menuju route yang benar | LULUS SECARA KODE | `FirebaseMessaging.onMessageOpenedApp` memanggil `_setRouteFromMessage`, yang membaca `data.route`. |
| Klik terminated menuju route yang benar | LULUS SECARA KODE | `FirebaseMessaging.instance.getInitialMessage()` diproses saat inisialisasi local notification. |
| Token/secret tidak di-hardcode atau di-log penuh | LULUS DENGAN CATATAN | Token perangkat tidak di-hardcode dan log hanya memakai `maskToken`. Nilai Firebase Web di `firebase_options.dart` adalah konfigurasi client publik, bukan secret. |

### Struktur class PushService

`PushService` sekarang menjadi satu service untuk kebutuhan prompt AI
challenge. Method publiknya adalah:

- `requestPermission()` untuk izin notifikasi Android/iOS.
- `initialize(onToken: ...)` untuk local notification, token awal,
  `onTokenRefresh`, listener foreground, klik background/terminated, dan
  subscribe topic.
- `subscribeToAnnouncementsTopic()` dan
  `unsubscribeFromAnnouncementsTopic()` untuk topic
  `pengumuman-kampus`.
- `getTokenPreview()` untuk tampilan token terpotong pada halaman debug.

`firebaseMessagingBackgroundHandler` tetap berada di luar class sebagai fungsi
top-level karena Firebase menjalankannya pada isolate terpisah.

Status **LULUS SECARA KODE** berarti alur sudah terhubung berdasarkan inspeksi
source code. Hasil runtime tetap harus dicatat setelah diuji pada perangkat
Android menggunakan matriks pengujian di atas.

### Perbedaan Android 13+ dan iOS

- **Android 13+:** `requestNotificationPermission()` meminta izin notifikasi
  runtime. Channel Android dibuat melalui
  `AndroidFlutterLocalNotificationsPlugin`, dan pesan foreground ditampilkan
  manual dengan `AndroidNotificationDetails`.
- **Android background/terminated:** payload `notification` ditampilkan oleh
  sistem. Kliknya diterima melalui `onMessageOpenedApp` atau
  `getInitialMessage`.
- **iOS:** `requestPermission()` meminta izin alert, badge, dan sound melalui
  APNs. Local notification menggunakan `DarwinNotificationSettings`.
  Konfigurasi APNs dan capability Push Notifications tetap harus diaktifkan
  pada project iOS.
- **Web:** Firebase Core dapat diinisialisasi, tetapi inisialisasi FCM runtime
  saat ini tidak dijalankan oleh aplikasi karena konfigurasi Web Push/VAPID
  belum disediakan.

### Kode yang tidak boleh mengakses `BuildContext`

`firebaseMessagingBackgroundHandler` berjalan di isolate terpisah dan tidak
boleh mengakses `BuildContext`, widget, Riverpod container, atau router.
Handler tersebut hanya melakukan inisialisasi Firebase ringan. Navigasi selalu
dilakukan di isolate utama setelah klik melalui notifier route dan GoRouter.

## Praktikum 7: Refactoring dan testing

### Hasil refactoring

- Semua route aplikasi dipusatkan di
  `lib/routes.dart` melalui `AppRoutes.home`, `AppRoutes.login`,
  `AppRoutes.announcementPattern`, dan `AppRoutes.announcement(id)`.
  GoRouter, daftar pengumuman, dan deep link FCM memakai sumber konstanta yang
  sama.
- Parsing payload dipindahkan ke fungsi murni
  `routeFromMessage(Map<String, dynamic> data)`. Route kosong menghasilkan
  `/`, sedangkan route tanpa slash awal dinormalisasi, misalnya
  `pengumuman/3` menjadi `/pengumuman/3`.
- Pemetaan `DioException` dipindahkan ke
  `lib/data/api_errors.dart` melalui `apiErrorMessage`. Interceptor API
  meneruskan pesan yang ramah pengguna untuk status 401, timeout, dan koneksi
  offline.

### Hasil testing

Test ditambahkan pada `test/auth_push_test.dart`. Firebase tidak dijalankan
secara langsung; test hanya memverifikasi logika di sekitarnya:

- parsing route dan ID pengumuman;
- status login berdasarkan token;
- sesi refresh kosong memaksa login ulang;
- pemetaan error 401, timeout, dan offline.

Perintah verifikasi:

```text
flutter analyze
flutter test
```

Hasil terakhir:

```text
flutter analyze:  No issues found
flutter test:     All tests passed
```

### Error umum

| Gejala | Penyebab umum | Solusi |
|---|---|---|
| Token null di emulator | Emulator tanpa Google Play Services | Gunakan emulator berikon Play Store atau perangkat fisik |
| Banner tidak muncul saat foreground | Mengandalkan banner otomatis sistem | Tampilkan manual melalui `flutter_local_notifications` di `onMessage` |
| Klik notifikasi tidak navigasi saat terminated | `getInitialMessage` tidak dipanggil saat startup | Panggil saat inisialisasi `PushService` dan teruskan `data.route` |
| 401 berulang meski sudah login | Refresh tidak mengulang request atau refresh kedaluwarsa | Refresh sekali, retry request, lalu clear sesi jika gagal |
| `MissingPluginException` | Hot reload setelah menambah plugin | Hentikan aplikasi dan jalankan ulang penuh |
| Notifikasi iOS tidak muncul | APNs key/capability belum dikonfigurasi | Konfigurasi APNs di Firebase Console dan Push Notifications di Xcode |

### Checklist verifikasi mandiri

- Token disimpan melalui `flutter_secure_storage`, bukan SharedPreferences,
  dan tidak dicetak penuh ke log.
- 401 memicu refresh sekali lalu retry; refresh yang gagal membersihkan sesi.
- Ketiga app state diuji menggunakan tabel bukti; klik masuk ke route yang benar.
- Topic digunakan untuk broadcast, token digunakan untuk pesan personal.
- `flutter analyze` dan seluruh unit test lulus.
