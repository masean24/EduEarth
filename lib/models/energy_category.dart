/// Model immutable untuk tabel `energy_categories`.
class EnergyCategory {
  const EnergyCategory({
    required this.id,
    required this.slug,
    required this.name,
    required this.shortCode,
    required this.description,
    required this.icon,
    required this.colorHex,
    this.comparison = const <String, dynamic>{},
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String slug;
  final String name;
  final String shortCode;
  final String description;
  final String icon;
  final String colorHex;
  final Map<String, dynamic> comparison;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory EnergyCategory.fromJson(Map<String, dynamic> json) {
    final rawComparison = json['comparison'];
    return EnergyCategory(
      id: (json['id'] as String?) ?? '',
      slug: (json['slug'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      shortCode: (json['short_code'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      icon: (json['icon'] as String?) ?? 'eco_rounded',
      colorHex: (json['color_hex'] as String?) ?? '#22C55E',
      comparison: rawComparison is Map<String, dynamic>
          ? Map<String, dynamic>.from(rawComparison)
          : const <String, dynamic>{},
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'name': name,
      'short_code': shortCode,
      'description': description,
      'icon': icon,
      'color_hex': colorHex,
      'comparison': comparison,
      'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  EnergyCategory copyWith({
    String? id,
    String? slug,
    String? name,
    String? shortCode,
    String? description,
    String? icon,
    String? colorHex,
    Map<String, dynamic>? comparison,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EnergyCategory(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      shortCode: shortCode ?? this.shortCode,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      colorHex: colorHex ?? this.colorHex,
      comparison: comparison ?? this.comparison,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

