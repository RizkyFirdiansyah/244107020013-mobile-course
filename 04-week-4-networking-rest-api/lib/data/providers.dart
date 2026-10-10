import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:async';

import 'api_client.dart';
import 'models/comment.dart';
import 'models/post.dart';
import 'repositories/comment_repository.dart';
import 'repositories/post_repository.dart';

final dioProvider = Provider<Dio>((ref) => createDio());

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(ref.watch(dioProvider)),
);

/// Provider untuk CommentRepository mengikuti pola dependency injection yang sama
/// Dio client sudah terpusat di dioProvider, repository hanya menerima instance-nya
final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(ref.watch(dioProvider)),
);

class PostListNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() async {
    // Exception dari repository otomatis menjadi AsyncError.
    // Inilah ekuivalen deklaratif dari AsyncValue.guard di versi lama.
    final repository = ref.watch(postRepositoryProvider);
    return repository.fetchPosts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(postRepositoryProvider);
      state = AsyncData(await repository.fetchPosts());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final postListProvider = AsyncNotifierProvider<PostListNotifier, List<Post>>(
  PostListNotifier.new,
  // Nonaktifkan retry otomatis Riverpod 3 agar error langsung
  // final dan mudah diuji (tanpa ini, future provider di-test
  // akan me-retry dan menggantung).
  retry: (retryCount, error) => null,
);

// ============================================================================
// Comments Provider (Comments dari Post tertentu)
// ============================================================================

/// AsyncNotifier untuk mengelola state comments dari satu post
///
/// State transitions:
/// 1. Initial: AsyncLoading (fetch dimulai)
/// 2. Success: AsyncData of `List<Comment>` dengan data dari server
/// 3. Error: AsyncError(exception, stacktrace) dengan pesan error user-friendly
///
/// Note: Menggunakan `.family` karena postId adalah parameter dinamis
/// Setiap postId punya cache state terpisah di Riverpod
class CommentsNotifier extends AsyncNotifier<List<Comment>> {
  CommentsNotifier(this.postId);

  final int postId;

  /// Build: dipanggil saat provider pertama kali di-watch
  ///
  /// Parameter:
  /// - arg: postId dari provider call ref.watch(commentsProvider(postId))
  ///
  /// Flow:
  /// 1. Ambil postId dari arg
  /// 2. Watch commentRepositoryProvider (jika provider berubah, rebuild otomatis)
  /// 3. Panggil fetchComments(postId) - exception otomatis jadi AsyncError
  @override
  Future<List<Comment>> build() async {
    // Exception dari repository otomatis menjadi AsyncError
    // Tidak perlu try-catch di sini; Riverpod menghandle semuanya
    final repository = ref.watch(commentRepositoryProvider);
    return repository.fetchComments(postId);
  }

  /// Manual refresh: user menekan tombol "Coba Lagi"
  ///
  /// Parameter:
  /// - postId: id post untuk refresh
  ///
  /// Flow:
  /// 1. Set state ke AsyncLoading untuk tampilkan loading indicator
  /// 2. Panggil fetchComments lagi
  /// 3. Jika sukses: AsyncData dengan data baru
  /// 4. Jika error: AsyncError dengan exception
  Future<void> refresh(int postId) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(commentRepositoryProvider);
      state = AsyncData(await repository.fetchComments(postId));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// AsyncNotifierProvider untuk comments dengan family modifier
///
/// Keunikan:
/// - Menerima parameter postId saat di-call: ref.watch(commentsProvider(postId))
/// - Setiap postId punya state terpisah (caching otomatis)
/// - Retry dinonaktifkan untuk error yang jelas dan testable
final commentsProvider =
    AsyncNotifierProvider.family<CommentsNotifier, List<Comment>, int>(
      CommentsNotifier.new,
      retry: (retryCount, error) => null,
    );

/// Helper khusus testing (letakkan di providers.dart): membaca state
/// pertama yang bukan loading lewat listener + completer, sehingga
/// test tidak menunggu retry dan tidak melakukan HTTP sungguhan.
Future<List<Post>> readPostsOnce(ProviderContainer container) {
  final completer = Completer<List<Post>>();
  final sub = container.listen<AsyncValue<List<Post>>>(postListProvider, (
    previous,
    next,
  ) {
    if (next.isLoading || completer.isCompleted) return;
    next.whenData(completer.complete);
    if (next.hasError) {
      completer.completeError(
        next.error ?? StateError('unknown error'),
        next.stackTrace ?? StackTrace.empty,
      );
    }
  }, fireImmediately: true);
  return completer.future.whenComplete(sub.close);
}

Future<Object?> readPostsErrorOnce(ProviderContainer container) {
  final completer = Completer<Object?>();
  final sub = container.listen<AsyncValue<List<Post>>>(postListProvider, (
    previous,
    next,
  ) {
    if (next.isLoading || completer.isCompleted) return;
    completer.complete(next.error);
  }, fireImmediately: true);
  return completer.future.whenComplete(sub.close);
}

String friendlyErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      /// Timeout errors: connectionTimeout, sendTimeout, receiveTimeout
      /// Penyebab: koneksi lambat atau server tidak merespons dalam 10 detik
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi lambat atau timeout. Periksa internet Anda lalu coba lagi.';

      /// Connection error: tidak bisa reach server sama sekali
      /// Penyebab: WiFi/data mati, DNS error, atau server offline
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa internet Anda.';

      /// Bad response: server merespons tapi dengan HTTP error code
      /// Pemetaan: 404 not found, 401/403 forbidden, 500+ server error
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 404) {
          return 'Data tidak ditemukan (404).';
        }
        if (code == 401 || code == 403) {
          return 'Akses ditolak ($code). Periksa kredensial Anda.';
        }
        if (code != null && code >= 500) {
          return 'Server bermasalah ($code). Coba lagi nanti.';
        }
        return 'Server bermasalah ($code). Coba lagi nanti.';

      /// Unknown error: tipe error lain yang tidak terpetakan
      default:
        return 'Terjadi kesalahan jaringan. Coba lagi.';
    }
  }

  /// Non-DioException: error dari sumber lain (parsing, logic, dll)
  return 'Terjadi kesalahan tak terduga: $error';
}
