/// Model immutable untuk tabel `quizzes`.
class Quiz {
  const Quiz({
    required this.id,
    required this.title,
    required this.description,
    this.categoryId,
    this.categorySlug,
    this.categoryName,
    this.categoryShortCode,
    this.difficulty = 'beginner',
    this.timeLimitSeconds,
    this.isPublished = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? categoryId;
  final String? categorySlug;
  final String? categoryName;
  final String? categoryShortCode;
  final String title;
  final String description;
  final String difficulty;
  final int? timeLimitSeconds;
  final bool isPublished;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Quiz.fromJson(Map<String, dynamic> json) {
    final nestedCategory = json['energy_categories'];
    String? catSlug = json['category_slug'] as String?;
    String? catName = json['category_name'] as String?;
    String? shortCode = json['category_short_code'] as String?;

    if (nestedCategory is Map<String, dynamic>) {
      catSlug ??= nestedCategory['slug'] as String?;
      catName ??= nestedCategory['name'] as String?;
      shortCode ??= nestedCategory['short_code'] as String?;
    }

    return Quiz(
      id: (json['id'] as String?) ?? '',
      categoryId: json['category_id'] as String?,
      categorySlug: catSlug,
      categoryName: catName,
      categoryShortCode: shortCode,
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      difficulty: (json['difficulty'] as String?) ?? 'beginner',
      timeLimitSeconds: (json['time_limit_seconds'] as num?)?.toInt(),
      isPublished: (json['is_published'] as bool?) ?? true,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      if (categorySlug != null) 'category_slug': categorySlug,
      if (categoryName != null) 'category_name': categoryName,
      if (categoryShortCode != null) 'category_short_code': categoryShortCode,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'time_limit_seconds': timeLimitSeconds,
      'is_published': isPublished,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  String get difficultyLabel {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return 'Pemula';
      case 'intermediate':
        return 'Menengah';
      case 'advanced':
        return 'Lanjutan';
      default:
        return 'Pemula';
    }
  }

  String get timeLimitLabel {
    if (timeLimitSeconds == null || timeLimitSeconds! <= 0) {
      return 'Tanpa batas waktu';
    }
    final minutes = (timeLimitSeconds! / 60).ceil();
    return '$minutes menit';
  }

  bool get isDraft =>
      title.toUpperCase().contains('[DRAF]') ||
      description.toUpperCase().contains('[DRAF');

  static DateTime? _parseDate(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
