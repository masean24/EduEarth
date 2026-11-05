/// Model immutable untuk tabel `power_plants` beserta metadata kategori,
/// presisi koordinat, catatan sumber, dan jarak.
class PowerPlant {
  const PowerPlant({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.province,
    required this.latitude,
    required this.longitude,
    this.description,
    this.categorySlug,
    this.categoryName,
    this.categoryShortCode,
    this.city,
    this.coordinatePrecision = 'exact',
    this.capacityMw,
    this.operationalStatus = 'unknown',
    this.operatorName,
    this.imageUrl,
    this.sourceUrl,
    this.sourceNotes,
    this.externalRef,
    this.dataAsOf,
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
  final String? description;
  final String province;
  final String? city;
  final double latitude;
  final double longitude;
  final String coordinatePrecision;
  final double? capacityMw;
  final String operationalStatus;
  final String? operatorName;
  final String? imageUrl;
  final String? sourceUrl;
  final String? sourceNotes;
  final String? externalRef;
  final String? dataAsOf;
  final DateTime? verifiedAt;
  final bool isDemo;
  final bool isPublished;

  /// Jarak dari pengguna dalam meter (terisi saat dipanggil melalui RPC `nearby_plants`).
  final double? distanceMeters;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Bernilai `true` apabila koordinat pembangkit merupakan lokasi perkiraan (`approximate`).
  bool get isApproximate =>
      coordinatePrecision.trim().toLowerCase() == 'approximate';

  /// Query pencarian Google Maps berupa gabungan `nama pembangkit + kota + provinsi`.
  String get googleMapsSearchQuery {
    final parts = <String>[
      name.trim(),
      if (city != null && city!.trim().isNotEmpty) city!.trim(),
      province.trim(),
    ].where((s) => s.isNotEmpty).toList();
    return parts.join(' ');
  }

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

    final rawDesc = json['description'] as String?;
    final rawPrecision = json['coordinate_precision'] as String?;

    return PowerPlant(
      id: (json['id'] as String?) ?? '',
      categoryId: (json['category_id'] as String?) ?? '',
      categorySlug: slug,
      categoryName: catName,
      categoryShortCode: shortCode,
      name: (json['name'] as String?) ?? '',
      description: (rawDesc != null && rawDesc.trim().isNotEmpty)
          ? rawDesc.trim()
          : null,
      province: (json['province'] as String?) ?? '',
      city: json['city'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      coordinatePrecision:
          (rawPrecision != null && rawPrecision.trim().isNotEmpty)
              ? rawPrecision.trim().toLowerCase()
              : 'exact',
      capacityMw: (json['capacity_mw'] as num?)?.toDouble(),
      operationalStatus:
          (json['operational_status'] as String?) ?? 'unknown',
      operatorName: json['operator_name'] as String?,
      imageUrl: json['image_url'] as String?,
      sourceUrl: json['source_url'] as String?,
      sourceNotes: json['source_notes'] as String?,
      externalRef: json['external_ref'] as String?,
      dataAsOf: json['data_as_of'] as String?,
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
      'coordinate_precision': coordinatePrecision,
      'capacity_mw': capacityMw,
      'operational_status': operationalStatus,
      'operator_name': operatorName,
      'image_url': imageUrl,
      'source_url': sourceUrl,
      'source_notes': sourceNotes,
      'external_ref': externalRef,
      'data_as_of': dataAsOf,
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
    String? coordinatePrecision,
    double? capacityMw,
    String? operationalStatus,
    String? operatorName,
    String? imageUrl,
    String? sourceUrl,
    String? sourceNotes,
    String? externalRef,
    String? dataAsOf,
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
      coordinatePrecision: coordinatePrecision ?? this.coordinatePrecision,
      capacityMw: capacityMw ?? this.capacityMw,
      operationalStatus: operationalStatus ?? this.operationalStatus,
      operatorName: operatorName ?? this.operatorName,
      imageUrl: imageUrl ?? this.imageUrl,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceNotes: sourceNotes ?? this.sourceNotes,
      externalRef: externalRef ?? this.externalRef,
      dataAsOf: dataAsOf ?? this.dataAsOf,
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
        return 'Konstruksi';
      case 'planned':
        return 'Rencana';
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
