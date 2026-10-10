import 'package:dio/dio.dart';

import '../models/comment.dart';

/// Repository untuk mengelola comment data dari JSONPlaceholder API
///
/// Tanggung jawab:
/// - Merangkul Dio client untuk mengatur interface jaringan
/// - Melakukan HTTP request ke endpoint comments dengan query parameter postId
/// - Parsing response JSON ke dalam list Comment models
/// - Menerapkan timeout 10 detik untuk setiap request
class CommentRepository {
  CommentRepository(this._dio);

  /// Dependency Injection: Dio client yang sudah dikonfigurasi di api_client.dart
  /// Alasan DI: memudahkan testing (mock Dio), dan memastikan config terpusat
  final Dio _dio;

  /// Fetch comments untuk post tertentu dari endpoint /comments?postId={id}
  ///
  /// Parameter:
  /// - postId: id postingan yang komentar-nya ingin diambil
  ///
  /// Return:
  /// - Future of `List<Comment>`: list komentar untuk post tersebut
  ///
  /// Exception:
  /// - DioException: jika koneksi timeout, network error, atau HTTP error
  ///   (error handling dilakukan di AsyncNotifierProvider, bukan di sini)
  ///
  /// Timeout config:
  /// Setiap request dibatasi 10 detik (dipadu dengan global timeout di api_client.dart).
  /// Jika melebihi, DioException dengan type connectionTimeout/receiveTimeout dilempar.
  Future<List<Comment>> fetchComments(int postId) async {
    // GET /comments?postId={id}
    // Response: List<Map<String, dynamic>> dari JSONPlaceholder
    final response = await _dio.get<List>(
      '/comments',
      queryParameters: {'postId': postId},
      // Override timeout untuk request ini saja (opsional, mengikuti global timeout)
      options: Options(
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    // Ekstrak data: response.data adalah List atau null
    final data = response.data ?? [];

    // Parse setiap item JSON ke Comment model
    // whereType<Map<String, dynamic>>() memfilter non-map items (safety layer)
    // .map(Comment.fromJson) memanggil factory constructor dengan error handling internal
    return data
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
  }
}
