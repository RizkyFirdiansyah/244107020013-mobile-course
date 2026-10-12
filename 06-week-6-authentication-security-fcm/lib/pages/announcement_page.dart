import 'package:flutter/material.dart';

class AnnouncementPage extends StatelessWidget {
  const AnnouncementPage({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) {
    final announcement = _announcements[id];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pengumuman'),
      ),
      body: announcement == null
          ? Center(
              child: Text('Pengumuman dengan ID $id tidak ditemukan.'),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.campaign,
                    size: 48,
                    color: Colors.indigo,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    announcement.title,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    announcement.date,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Divider(height: 32),
                  Text(
                    announcement.body,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ID pengumuman: $id',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Announcement {
  const _Announcement({
    required this.title,
    required this.body,
    required this.date,
  });

  final String title;
  final String body;
  final String date;
}

const _announcements = {
  '3': _Announcement(
    title: 'Jadwal kuliah berubah',
    body:
        'Kelas Mobile pindah ke Ruang A2 jam 13.00. '
        'Mohon hadir 10 menit sebelum perkuliahan dimulai.',
    date: '12 Oktober 2026 • Akademik',
  ),
  '2': _Announcement(
    title: 'Pengumpulan tugas praktikum',
    body:
        'Pastikan tugas praktikum dikumpulkan melalui LMS sebelum batas '
        'waktu yang telah ditentukan.',
    date: '11 Oktober 2026 • Praktikum',
  ),
  '1': _Announcement(
    title: 'Informasi akademik kampus',
    body:
        'Informasi akademik terbaru untuk mahasiswa tersedia pada portal '
        'kampus.',
    date: '12 Oktober 2026 • Kampus',
  ),
};