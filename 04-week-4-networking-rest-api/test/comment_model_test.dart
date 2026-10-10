import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/comment.dart';

void main() {
  group('Comment.fromJson - Null Safety Tests', () {
    /// Test Case 1: Happy path - semua field tersedia dan valid
    ///
    /// Verifikasi: Comment diparse dengan benar jika semua field lengkap
    /// Expected: Semua field harus sesuai dengan input JSON
    test('should create Comment from valid JSON with all fields', () {
      // Arrange: JSON response yang lengkap dari JSONPlaceholder
      final json = {
        'postId': 1,
        'id': 1,
        'name': 'John Doe',
        'email': 'john@example.com',
        'body': 'This is a great post!',
      };

      // Act: Parse JSON ke Comment
      final comment = Comment.fromJson(json);

      // Assert: Semua field harus sesuai
      expect(comment.postId, 1);
      expect(comment.id, 1);
      expect(comment.name, 'John Doe');
      expect(comment.email, 'john@example.com');
      expect(comment.body, 'This is a great post!');
    });

    /// Test Case 2: Edge case - postId field hilang
    ///
    /// Verifikasi: fromJson tidak crash jika postId hilang/null
    /// Expected: postId harus default ke 0
    /// Alasan: API response kadang incomplete atau ada versi lama
    test('should use default postId (0) when field is missing', () {
      // Arrange: JSON tanpa field postId
      final json = {
        'id': 2,
        'name': 'Jane Doe',
        'email': 'jane@example.com',
        'body': 'Nice article!',
        // postId tidak ada
      };

      // Act
      final comment = Comment.fromJson(json);

      // Assert: postId harus 0 (default)
      expect(comment.postId, 0);
      // Pastikan field lain tetap valid
      expect(comment.id, 2);
      expect(comment.name, 'Jane Doe');
    });

    /// Test Case 3: Edge case - id field hilang
    ///
    /// Verifikasi: fromJson tidak crash jika id hilang
    /// Expected: id default ke 0
    test('should use default id (0) when field is missing', () {
      // Arrange
      final json = {
        'postId': 1,
        // id tidak ada
        'name': 'Alice',
        'email': 'alice@example.com',
        'body': 'Great content',
      };

      // Act
      final comment = Comment.fromJson(json);

      // Assert
      expect(comment.id, 0);
      expect(comment.postId, 1);
    });

    /// Test Case 4: Edge case - name field hilang
    ///
    /// Verifikasi: fromJson tidak crash jika name hilang
    /// Expected: name default ke '' (empty string)
    test('should use default name ("") when field is missing', () {
      // Arrange
      final json = {
        'postId': 1,
        'id': 3,
        // name tidak ada
        'email': 'noname@example.com',
        'body': 'Comment without name',
      };

      // Act
      final comment = Comment.fromJson(json);

      // Assert
      expect(comment.name, '');
      expect(comment.id, 3);
    });

    /// Test Case 5: Edge case - email field hilang
    ///
    /// Verifikasi: fromJson tidak crash jika email hilang
    /// Expected: email default ke ''
    test('should use default email ("") when field is missing', () {
      // Arrange
      final json = {
        'postId': 2,
        'id': 4,
        'name': 'Bob',
        // email tidak ada
        'body': 'No email comment',
      };

      // Act
      final comment = Comment.fromJson(json);

      // Assert
      expect(comment.email, '');
      expect(comment.name, 'Bob');
    });

    /// Test Case 6: Edge case - body field hilang
    ///
    /// Verifikasi: fromJson tidak crash jika body hilang
    /// Expected: body default ke ''
    test('should use default body ("") when field is missing', () {
      // Arrange
      final json = {
        'postId': 3,
        'id': 5,
        'name': 'Charlie',
        'email': 'charlie@example.com',
        // body tidak ada
      };

      // Act
      final comment = Comment.fromJson(json);

      // Assert
      expect(comment.body, '');
      expect(comment.name, 'Charlie');
    });

    /// Test Case 7: Edge case - semua field numeric menjadi string (type mismatch)
    ///
    /// Verifikasi: fromJson handle type mismatch dengan cast aman
    /// Expected: String field ditolak dan diganti default, int diconvert jika bisa
    test('should handle type mismatches gracefully', () {
      // Arrange: Beberapa field bertipe salah
      final json = {
        'postId': '1', // Seharusnya int, tapi string
        'id': 2.5, // Seharusnya int, tapi double (num)
        'name': 123, // Seharusnya String, tapi int
        'email': null, // Seharusnya String, tapi null
        'body': ['list'], // Seharusnya String, tapi list
      };

      // Act: Seharusnya tidak crash
      final comment = Comment.fromJson(json);

      // Assert:
      // - postId: string '1' -> cast gagal -> default 0
      expect(comment.postId, 0);
      // - id: double 2.5 -> as num? berhasil -> toInt() = 2
      expect(comment.id, 2);
      // - name: int 123 -> as String? gagal -> default ''
      expect(comment.name, '');
      // - email: null -> as String? gagal -> default ''
      expect(comment.email, '');
      // - body: list -> as String? gagal -> default ''
      expect(comment.body, '');
    });

    /// Test Case 8: Edge case - JSON kosong {}
    ///
    /// Verifikasi: fromJson dari JSON empty object
    /// Expected: Semua field default
    test('should use all defaults when JSON is empty', () {
      // Arrange
      final json = <String, dynamic>{};

      // Act
      final comment = Comment.fromJson(json);

      // Assert
      expect(comment.postId, 0);
      expect(comment.id, 0);
      expect(comment.name, '');
      expect(comment.email, '');
      expect(comment.body, '');
    });

    /// Test Case 9: Double value untuk numeric field
    ///
    /// Verifikasi: Double (2.9) ke int conversion
    /// Expected: 2.9 -> toInt() -> 2 (bukan 3, tidak round)
    test('should correctly convert double to int', () {
      // Arrange
      final json = {
        'postId': 1.9, // Double bukan int
        'id': 5.1,
        'name': 'Test',
        'email': 'test@example.com',
        'body': 'Test body',
      };

      // Act
      final comment = Comment.fromJson(json);

      // Assert: toInt() truncate, tidak round
      expect(comment.postId, 1); // 1.9 -> 1
      expect(comment.id, 5); // 5.1 -> 5
    });

    /// Test Case 10: Equality dan hashCode dengan default values
    ///
    /// Verifikasi: Dua Comment dengan field missing sama harus equal
    /// Expected: Equality check dan hashCode konsisten
    test('should handle equality correctly with default values', () {
      // Arrange: Dua JSON berbeda tapi parse jadi field yang sama
      final json1 = {'id': 1}; // Hanya id
      final json2 = <String, dynamic>{}; // Kosong

      // Act
      final comment1 = Comment.fromJson(json1);
      final comment2 = Comment.fromJson(json1); // Same JSON
      final comment3 = Comment.fromJson(json2); // Different JSON

      // Assert
      expect(comment1, comment2); // Same JSON -> equal
      expect(comment1 != comment3, true); // Different JSON -> not equal
      expect(comment1.hashCode, comment2.hashCode); // Same -> same hash
    });

    /// Test Case 11: toJson roundtrip dengan missing fields
    ///
    /// Verifikasi: fromJson -> toJson -> fromJson cycle
    /// Expected: Value tetap konsisten setelah roundtrip
    test('should roundtrip correctly through toJson', () {
      // Arrange: Incomplete JSON
      final json = {
        'postId': 10,
        'id': 20,
        // name, email, body missing
      };

      // Act: Parse -> serialize -> parse lagi
      final comment1 = Comment.fromJson(json);
      final serialized = comment1.toJson();
      final comment2 = Comment.fromJson(serialized);

      // Assert: Harus identik
      expect(comment1, comment2);
      expect(serialized['postId'], 10);
      expect(serialized['id'], 20);
      expect(serialized['name'], ''); // Default values
      expect(serialized['email'], '');
      expect(serialized['body'], '');
    });

    /// Test Case 12: Null value vs missing field
    ///
    /// Verifikasi: Bedanya null vs field tidak ada
    /// Expected: Keduanya treat sama (default value)
    test('should treat null value same as missing field', () {
      // Arrange
      final jsonMissing = {
        'postId': 1,
        'id': 1,
        // name missing
        'email': 'test@example.com',
        'body': 'test',
      };

      final jsonNull = {
        'postId': 1,
        'id': 1,
        'name': null, // Explicit null
        'email': 'test@example.com',
        'body': 'test',
      };

      // Act
      final comment1 = Comment.fromJson(jsonMissing);
      final comment2 = Comment.fromJson(jsonNull);

      // Assert: Harus sama
      expect(comment1.name, '');
      expect(comment2.name, '');
      expect(comment1, comment2);
    });
  });
}
