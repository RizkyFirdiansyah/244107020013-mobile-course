import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../messaging/push_service.dart';
import '../providers/auth_provider.dart';

const _announcements = [
  (
    id: '3',
    title: 'Jadwal kuliah berubah',
    summary: 'Kelas Mobile pindah ke Ruang A2 jam 13.00.',
    date: 'Hari ini',
  ),
  (
    id: '2',
    title: 'Pengumpulan tugas praktikum',
    summary: 'Pastikan tugas dikumpulkan sebelum batas waktu.',
    date: 'Kemarin',
  ),
  (
    id: '1',
    title: 'Informasi akademik kampus',
    summary: 'Lihat informasi akademik terbaru untuk mahasiswa.',
    date: '12 Okt 2026',
  ),
];

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String? _tokenPreview;

  @override
  void initState() {
    super.initState();
    _loadTokenPreview();
  }

  Future<void> _loadTokenPreview() async {
    final preview = await pushService.getTokenPreview();
    if (mounted) setState(() => _tokenPreview = preview);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: [
          IconButton(
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pengumuman terbaru',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Informasi penting untuk kegiatan perkuliahan Anda.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              for (final announcement in _announcements)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const CircleAvatar(
                      child: Icon(Icons.campaign_outlined),
                    ),
                    title: Text(
                      announcement.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${announcement.summary}\n${announcement.date}',
                      ),
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/pengumuman/${announcement.id}'),
                  ),
                ),
              if (_tokenPreview != null) ...[
                const SizedBox(height: 12),
                Text(
                  'FCM aktif',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Text(
                  'Token perangkat: $_tokenPreview',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
