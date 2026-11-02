import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/learning_material.dart';
import '../../data/learning_repository.dart';

final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  return const LearningRepository();
});

/// Seluruh daftar materi pembelajaran yang terpublikasi.
final allLearningMaterialsProvider =
    FutureProvider<List<LearningMaterial>>((ref) async {
  final repo = ref.watch(learningRepositoryProvider);
  return repo.getPublishedMaterials();
});

/// Daftar materi pembelajaran untuk satu `categorySlug`.
final materialsByCategorySlugProvider =
    FutureProvider.family<List<LearningMaterial>, String>((
  ref,
  categorySlug,
) async {
  final repo = ref.watch(learningRepositoryProvider);
  return repo.getPublishedMaterials(categorySlug: categorySlug);
});

/// Detail materi pembelajaran berdasarkan `slug`.
final learningMaterialDetailProvider =
    FutureProvider.family<LearningMaterial, String>((ref, slug) async {
  final repo = ref.watch(learningRepositoryProvider);
  return repo.getMaterialBySlug(slug);
});
