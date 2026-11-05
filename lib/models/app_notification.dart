/// Model untuk tabel `notifications` (pengumuman publik satu arah).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.isPublished,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String category;
  final bool isPublished;
  final DateTime createdAt;

  bool get isExample =>
      title.toUpperCase().contains('[CONTOH]') ||
      title.toUpperCase().contains('[DEMO]');

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['created_at'] as String?;
    return AppNotification(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      category: (json['category'] as String?) ?? 'info',
      isPublished: (json['is_published'] as bool?) ?? false,
      createdAt: createdAtRaw != null
          ? (DateTime.tryParse(createdAtRaw) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'category': category,
      'is_published': isPublished,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

