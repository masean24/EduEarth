/// Model immutable untuk tabel `power_plants` beserta metadata kategori & jarak.
class PowerPlant {
  const PowerPlant({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.province,
    required this.latitude,
    required this.longitude,
    this.categorySlug,
    this.categoryName,
    this.categoryShortCode,
    this.city,
    this.capacityMw,
    this.operationalStatus = 'unknown',
    this.operatorName,
    this.imageUrl,
    this.sourceUrl,
    this.verifiedAt,
    this.isDemo = false,
    this.isPublished = true,
    this.distanceMeters,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String categoryId;
  final String? categorySlug;
  final String? categoryName;
  final String? categoryShortCode;
  final String name;
  final String description;
  final String province;
  final String? city;
  final double latitude;
  final double longitude;
  final double? capacityMw;
  final String operationalStatus;
  final String? operatorName;
  final String? imageUrl;
  final String? sourceUrl;
  final DateTime? verifiedAt;
  final bool isDemo;
  final bool isPublished;

  /// Jarak dari pengguna dalam meter (terisi saat dipanggil melalui RPC `nearby_plants`).
  final double? distanceMeters;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PowerPlant.fromJson(Map<String, dynamic> json) {
    final nestedCategory = json['energy_categories'];
    String? slug = json['category_slug'] as String?;
    String? catName = json['category_name'] as String?;
    String? shortCode = json['category_short_code'] as String?;

    if (nestedCategory is Map<String, dynamic>) {
      slug ??= nestedCategory['slug'] as String?;
      catName ??= nestedCategory['name'] as String?;
      shortCode ??= nestedCategory['short_code'] as String?;
    }

    return PowerPlant(
      id: (json['id'] as String?) ?? '',
      categoryId: (json['category_id'] as String?) ?? '',
      categorySlug: slug,
      categoryName: catName,
      categoryShortCode: shortCode,
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      province: (json['province'] as String?) ?? '',
      city: json['city'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      capacityMw: (json['capacity_mw'] as num?)?.toDouble(),
      operationalStatus:
          (json['operational_status'] as String?) ?? 'unknown',
      operatorName: json['operator_name'] as String?,
      imageUrl: json['image_url'] as String?,
      sourceUrl: json['source_url'] as String?,
      verifiedAt: _parseDate(json['verified_at']),
      isDemo: (json['is_demo'] as bool?) ?? false,
      isPublished: (json['is_published'] as bool?) ?? true,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
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
      'name': name,
      'description': description,
      'province': province,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'capacity_mw': capacityMw,
      'operational_status': operationalStatus,
      'operator_name': operatorName,
      'image_url': imageUrl,
      'source_url': sourceUrl,
      if (verifiedAt != null) 'verified_at': verifiedAt!.toIso8601String(),
      'is_demo': isDemo,
      'is_published': isPublished,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  PowerPlant copyWith({
    String? id,
    String? categoryId,
    String? categorySlug,
    String? categoryName,
    String? categoryShortCode,
    String? name,
    String? description,
    String? province,
    String? city,
    double? latitude,
    double? longitude,
    double? capacityMw,
    String? operationalStatus,
    String? operatorName,
    String? imageUrl,
    String? sourceUrl,
    DateTime? verifiedAt,
    bool? isDemo,
    bool? isPublished,
    double? distanceMeters,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PowerPlant(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categorySlug: categorySlug ?? this.categorySlug,
      categoryName: categoryName ?? this.categoryName,
      categoryShortCode: categoryShortCode ?? this.categoryShortCode,
      name: name ?? this.name,
      description: description ?? this.description,
      province: province ?? this.province,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      capacityMw: capacityMw ?? this.capacityMw,
      operationalStatus: operationalStatus ?? this.operationalStatus,
      operatorName: operatorName ?? this.operatorName,
      imageUrl: imageUrl ?? this.imageUrl,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      isDemo: isDemo ?? this.isDemo,
      isPublished: isPublished ?? this.isPublished,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Label status operasional dalam Bahasa Indonesia.
  String get operationalStatusLabel {
    switch (operationalStatus.toLowerCase()) {
      case 'operating':
        return 'Beroperasi';
      case 'construction':
        return 'Dalam Konstruksi';
      case 'planned':
        return 'Direncanakan';
      default:
        return 'Belum Diverifikasi';
    }
  }

  /// Lokasi ringkas (Kota, Provinsi atau Provinsi).
  String get locationLabel {
    final trimmedCity = city?.trim() ?? '';
    if (trimmedCity.isNotEmpty) {
      return '$trimmedCity, $province';
    }
    return province;
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

