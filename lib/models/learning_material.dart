/// Model immutable untuk tabel `learning_materials`.
class LearningMaterial {
  const LearningMaterial({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.slug,
    required this.summary,
    required this.contentMd,
    this.categorySlug,
    this.categoryName,
    this.categoryShortCode,
    this.coverImageUrl,
    this.readMinutes = 5,
    this.difficulty = 'beginner',
    this.sortOrder = 0,
    this.isPublished = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String categoryId;
  final String? categorySlug;
  final String? categoryName;
  final String? categoryShortCode;
  final String title;
  final String slug;
  final String summary;
  final String contentMd;
  final String? coverImageUrl;
  final int readMinutes;
  final String difficulty;
  final int sortOrder;
  final bool isPublished;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory LearningMaterial.fromJson(Map<String, dynamic> json) {
    final nestedCategory = json['energy_categories'];
    String? catSlug = json['category_slug'] as String?;
    String? catName = json['category_name'] as String?;
    String? shortCode = json['category_short_code'] as String?;

    if (nestedCategory is Map<String, dynamic>) {
      catSlug ??= nestedCategory['slug'] as String?;
      catName ??= nestedCategory['name'] as String?;
      shortCode ??= nestedCategory['short_code'] as String?;
    }

    return LearningMaterial(
      id: (json['id'] as String?) ?? '',
      categoryId: (json['category_id'] as String?) ?? '',
      categorySlug: catSlug,
      categoryName: catName,
      categoryShortCode: shortCode,
      title: (json['title'] as String?) ?? '',
      slug: (json['slug'] as String?) ?? '',
      summary: (json['summary'] as String?) ?? '',
      contentMd: (json['content_md'] as String?) ?? '',
      coverImageUrl: json['cover_image_url'] as String?,
      readMinutes: (json['read_minutes'] as num?)?.toInt() ?? 5,
      difficulty: (json['difficulty'] as String?) ?? 'beginner',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
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
      'slug': slug,
      'summary': summary,
      'content_md': contentMd,
      'cover_image_url': coverImageUrl,
      'read_minutes': readMinutes,
      'difficulty': difficulty,
      'sort_order': sortOrder,
      'is_published': isPublished,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  LearningMaterial copyWith({
    String? id,
    String? categoryId,
    String? categorySlug,
    String? categoryName,
    String? categoryShortCode,
    String? title,
    String? slug,
    String? summary,
    String? contentMd,
    String? coverImageUrl,
    int? readMinutes,
    String? difficulty,
    int? sortOrder,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LearningMaterial(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categorySlug: categorySlug ?? this.categorySlug,
      categoryName: categoryName ?? this.categoryName,
      categoryShortCode: categoryShortCode ?? this.categoryShortCode,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      summary: summary ?? this.summary,
      contentMd: contentMd ?? this.contentMd,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      readMinutes: readMinutes ?? this.readMinutes,
      difficulty: difficulty ?? this.difficulty,
      sortOrder: sortOrder ?? this.sortOrder,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
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

  bool get isDraft =>
      title.toUpperCase().contains('[DRAF]') ||
      summary.toUpperCase().contains('[DRAF');

  static DateTime? _parseDate(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
