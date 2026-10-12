import 'package:dio/dio.dart';

String apiErrorMessage(DioException error) {
  final status = error.response?.statusCode;
  if (status == 401) return 'Sesi Anda telah berakhir. Silakan login kembali.';
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout) {
    return 'Server terlalu lama merespons. Coba lagi.';
  }
  if (error.type == DioExceptionType.connectionError) {
    return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
  }
  return 'Terjadi kesalahan saat menghubungi server.';
}
