import 'learning_material.dart';
import 'power_plant.dart';

/// Model immutable untuk tabel `bookmarks` beserta relasi opsional ke
/// `LearningMaterial` atau `PowerPlant`.
class Bookmark {
  const Bookmark({
    required this.id,
    required this.userId,
    this.materialId,
    this.plantId,
    this.material,
    this.plant,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String? materialId;
  final String? plantId;
  final LearningMaterial? material;
  final PowerPlant? plant;
  final DateTime? createdAt;

  bool get isMaterialBookmark => materialId != null;
  bool get isPlantBookmark => plantId != null;

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    final rawMaterial = json['learning_materials'];
    final rawPlant = json['power_plants'];

    return Bookmark(
      id: (json['id'] as String?) ?? '',
      userId: (json['user_id'] as String?) ?? '',
      materialId: json['material_id'] as String?,
      plantId: json['plant_id'] as String?,
      material: rawMaterial is Map<String, dynamic>
          ? LearningMaterial.fromJson(rawMaterial)
          : null,
      plant: rawPlant is Map<String, dynamic>
          ? PowerPlant.fromJson(rawPlant)
          : null,
      createdAt: _parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'material_id': materialId,
      'plant_id': plantId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
