/// Model untuk Comment dari JSONPlaceholder API
/// 
/// Struktur data:
/// - postId: id postingan yang memiliki komentar ini
/// - id: id unik komentar
/// - name: nama pemberi komentar
/// - email: email pemberi komentar
/// - body: isi komentar
class Comment {
  const Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  final int postId;
  final int id;
  final String name;
  final String email;
  final String body;

  /// Factory constructor untuk parsing JSON dari API dengan null-safety
  /// 
  /// Penjelasan penanganan null:
  /// 1. (json['fieldName'] as Type?) melakukan cast aman (tidak crash jika null)
  /// 2. ?? 0 / ?? '' menyediakan nilai default jika cast gagal atau field hilang
  /// 3. Untuk int/num dari API: (json['postId'] as num?)?.toInt() ?? 0
  ///    - `as num?` mencegah crash jika bukan angka
  ///    - ?.toInt() hanya dipanggil jika hasilnya non-null
  ///    - ?? 0 memberikan fallback default
  /// 4. Untuk string: (json['name'] as String?) ?? ''
  ///    - `as String?` mencegah crash jika bukan string
  ///    - ?? '' memberikan fallback string kosong
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      // postId: int, default 0 jika field hilang atau null
      postId: json['postId'] is num ? (json['postId'] as num).toInt() : 0,
      
      // id: int, default 0 jika field hilang atau null
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      
      // name: String, default '' jika field hilang atau null
      name: json['name'] is String ? json['name'] as String : '',
      
      // email: String, default '' jika field hilang atau null
      email: json['email'] is String ? json['email'] as String : '',
      
      // body: String, default '' jika field hilang atau null
      body: json['body'] is String ? json['body'] as String : '',
    );
  }

  /// Convert Comment ke `Map<String, dynamic>` untuk JSON serialization
  Map<String, dynamic> toJson() => {
    'postId': postId,
    'id': id,
    'name': name,
    'email': email,
    'body': body,
  };

  @override
  String toString() =>
    'Comment(postId: $postId, id: $id, name: $name, email: $email, body: $body)';

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Comment &&
        runtimeType == other.runtimeType &&
        postId == other.postId &&
        id == other.id &&
        name == other.name &&
        email == other.email &&
        body == other.body;

  @override
  int get hashCode =>
    postId.hashCode ^
    id.hashCode ^
    name.hashCode ^
    email.hashCode ^
    body.hashCode;
}
