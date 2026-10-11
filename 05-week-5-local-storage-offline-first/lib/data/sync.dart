import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'api_client.dart';
import 'local/db.dart';
import 'models/post.dart';
import 'repositories/note_repository.dart';

/// Toggle simulasi offline yang deterministik, agar demo dan testing tidak
/// bergantung pada kondisi jaringan sungguhan.
class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final forceOfflineProvider = NotifierProvider<ForceOfflineNotifier, bool>(
  ForceOfflineNotifier.new,
);

final dioProvider = Provider<Dio>((ref) => createDio());

/// Membaca cache post dari tabel `cached_posts`.
Future<List<Post>> readCachedPosts({
  Future<Database> Function()? openDb,
}) async {
  final db = await (openDb ?? openNotesDb)();
  final rows = await db.query('cached_posts', orderBy: 'cached_at DESC');
  return rows.map((row) {
    final payload = row['payload'] as String? ?? '{}';
    return Post.fromJson(jsonDecode(payload) as Map<String, dynamic>);
  }).toList();
}

/// Menyimpan hasil fetch ke tabel `cached_posts` untuk kunjungan berikutnya.
Future<void> saveCachedPosts(
  List<Post> posts, {
  Future<Database> Function()? openDb,
}) async {
  final db = await (openDb ?? openNotesDb)();
  final batch = db.batch();
  for (final post in posts) {
    batch.insert('cached_posts', {
      'id': post.id,
      'payload': jsonEncode(post.toJson()),
      'cached_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
  await batch.commit(noResult: true);
}

/// Cache-first read untuk data API: kembalikan cache lokal seketika agar UI
/// tidak blank saat offline, lalu refresh dari jaringan di background.
class PostsCacheNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() => loadPostsCacheFirst();

  Future<List<Post>> loadPostsCacheFirst() async {
    final cached = await readCachedPosts();
    unawaited(refreshPostsInBackground());
    return cached;
  }

  Future<void> refreshPostsInBackground() async {
    if (ref.read(forceOfflineProvider)) return;
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get<List>('/posts');
      final data = response.data ?? [];
      final posts = data
          .whereType<Map>()
          .map((json) => Post.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      await saveCachedPosts(posts);
      state = AsyncData(posts);
    } on DioException {
      // Offline/gagal: biarkan cache lama tetap tampil.
    }
  }
}

final postsCacheProvider =
    AsyncNotifierProvider<PostsCacheNotifier, List<Post>>(
      PostsCacheNotifier.new,
      retry: (retryCount, error) => null,
    );

/// Sinkronisasi catatan kotor (dirty). Karena codelab belum punya backend tulis,
/// server disimulasikan dengan delay; yang dinilai adalah mekanismenya.
Future<int> syncNotes(NoteRepository repo) async {
  final dirtyCount = await repo.countDirty();
  if (dirtyCount == 0) return 0;
  // Simulasi upload: pada project nyata, kirim tiap catatan dirty
  // ke REST API di sini, lalu tandai bersih bila server menjawab 2xx.
  await Future.delayed(const Duration(seconds: 1));
  await repo.markAllSynced();
  return dirtyCount;
}
