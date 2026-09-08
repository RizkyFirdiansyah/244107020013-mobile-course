# 📱 Week 01 - Mobile Development Ecosystem & Flutter Refresh

Dokumentasi tugas dan praktikum minggu ke-1 mata kuliah Pemrograman Mobile. Fokus utama praktikum minggu ini adalah pengenalan ekosistem Flutter, konfigurasi environment development, pembuatan UI profil sederhana, serta pemahaman konsep dasar deklaratif UI.

---

## 🎯 Tujuan Praktikum

- Memahami ekosistem dan arsitektur dasar Flutter & Dart.
- Melakukan setup environment development Flutter SDK dan IDE (Android Studio / VS Code).
- Menjalankan aplikasi Flutter pada perangkat fisik/emulator.
- Mengubah UI default counter menjadi tampilan Profil Mahasiswa menggunakan widget dasar (`Scaffold`, `Column`, `Text`, `Icon`, dll).
- Menganalisis hasil `flutter doctor` dan menyelesaikan kendala setup awal.

---

## 🛠️ Stack Teknologi

- **Framework:** Flutter (Channel stable, v3.47.2)
- **Language:** Dart v3.13.2
- **Tools:** Visual Studio Code / Android Studio, Git
- **Target Platform:** Android

---

## 📸 Hasil Praktikum & Mini Assignment

### 1. Hasil Praktikum Pertama

Tampilan awal praktikum mengubah UI default menjadi profil sederhana yang menampilkan ikon, nama, dan deskripsi tugas.

![Hasil Praktikum 1](screenshots/praktikum-1.jpg)

### 2. Hasil Mini Assignment

Pengembangan dari tampilan awal dengan menambahkan informasi identitas lengkap seperti **NIM (244107020013)** serta informasi kelas dan nomor absen (**Kelas 2E, Absen 15**).

![Hasil Mini Assignment](screenshots/mini-assignment.jpg)

---

## ⚠️ Kendala Setup & Solusi

Saat melakukan pengecekan ketersediaan environment menggunakan `flutter doctor`, ditemukan beberapa _warning_ dan kendala:

1. **Peringatan PATH System Windows (`System32/flutter`)**
   - **Problem:** Path `flutter` di-resolve ke `C:\Windows\System32\flutter` alih-alih lokasi instalasi SDK utama `C:\flutter`.
   - **Solusi:** Memindahkan urutan `C:\flutter\bin` ke baris paling atas di Environment Variables (System PATH) Windows.

2. **Kebutuhan Android SDK 36**
   - **Problem:** Flutter 3.47.2 membutuhkan versi Android SDK 36, sedangkan SDK terpasang berada di versi 34.0.0 (`X Flutter requires Android SDK 36`).
   - **Solusi:** Membuka **Android Studio > SDK Manager > SDK Platforms**, lalu mengunduh paket Android SDK Build-Tools versi 36.

---

## 🚀 Cara Menjalankan Aplikasi

1. Pastikan Flutter SDK sudah terpasang dan dikonfigurasi dengan benar.
2. Buka terminal lalu navigasi ke folder project ini:
   ```bash
   cd 01-week-1-mobile-development-ecosystem-flutter-refresh
   ```
3. Unduh seluruh dependensi project:
   ```bash
   flutter pub get
   ```
4. Hubungkan perangkat Android/emulator, lalu jalankan aplikasi:
   ```bash
   flutter run
   ```

---

## 🧠 Refleksi Pembelajaran

1. **Kapan native lebih tepat dipilih daripada cross-platform?**
   Native (Kotlin/Swift) lebih tepat dipilih ketika aplikasi membutuhkan akses mendalam ke hardware berkinerja tinggi (seperti pemrosesan grafis 3D/AR kompleks, Bluetooth Low Energy tingkat lanjut) atau ketika aplikasi menggunakan fitur sistem operasi terbaru yang belum didukung oleh modul cross-platform.
2. **Bagaimana perubahan state berhubungan dengan widget tree dan UI deklaratif?**
   Dalam paradigma UI deklaratif (UI = f(state)), tampilan dibentuk dari struktur widget tree. Ketika terjadi perubahan state, Flutter tidak mengubah bagian UI secara langsung melainkan membangun ulang (rebuild) sub-tree widget yang relevan untuk mencerminkan kondisi state terbaru.
3. **Mengapa commit kecil dengan pesan jelas bermanfaat bagi pekerjaan tim dan portfolio?**
   Commit yang atomic dan deskriptif mempermudah penelusuran riwayat perubahan kode (debugging), memperlancar proses code review antar tim, serta memperlihatkan alur berpikir teknis yang terstruktur pada portofolio GitHub.
