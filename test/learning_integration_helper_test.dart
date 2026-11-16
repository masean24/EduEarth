import 'package:eduearth/core/constants/demo_data.dart';
import 'package:eduearth/features/auth/presentation/providers/auth_provider.dart';
import 'package:eduearth/features/learning/domain/learning_integration_helper.dart';
import 'package:eduearth/features/learning/presentation/providers/reading_progress_provider.dart';
import 'package:eduearth/features/quiz/presentation/providers/quiz_providers.dart';
import 'package:eduearth/models/learning_material.dart';
import 'package:eduearth/models/power_plant.dart';
import 'package:eduearth/models/quiz_attempt.dart';
import 'package:eduearth/routes/route_names.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LearningIntegrationHelper - SmartQuizResolver', () {
    final quizzes = DemoData.quizzes;

    LearningMaterial buildMaterial({
      required String slug,
      String? categorySlug,
    }) {
      return LearningMaterial(
        id: 'id-$slug',
        categoryId: 'cat-${categorySlug ?? "general"}',
        title: 'Judul $slug',
        slug: slug,
        summary: 'Ringkasan $slug',
        contentMd: 'Isi $slug',
        categorySlug: categorySlug,
      );
    }

    test('maps solar material to Solar & Wind + BESS quiz (1102)', () {
      final res = LearningIntegrationHelper.resolveRecommendedQuizForMaterial(
        material: buildMaterial(
          slug: 'draf-konsep-dasar-plts',
          categorySlug: 'solar',
        ),
        availableQuizzes: quizzes,
      );
      expect(res.isDirectTopicMatch, isTrue);
      expect(res.quiz?.id, '11111111-1111-4111-8111-111111111102');
    });

    test(
      'maps wind material to Solar & Wind + BESS quiz (1102) despite quiz categorySlug being solar',
      () {
        final res = LearningIntegrationHelper.resolveRecommendedQuizForMaterial(
          material: buildMaterial(
            slug: 'draf-konsep-dasar-pltb',
            categorySlug: 'wind',
          ),
          availableQuizzes: quizzes,
        );
        expect(res.isDirectTopicMatch, isTrue);
        expect(res.quiz?.id, '11111111-1111-4111-8111-111111111102');
      },
    );

    test(
      'maps hydro material to Hydro & Geothermal quiz (1103) despite quiz categorySlug being geothermal',
      () {
        final res = LearningIntegrationHelper.resolveRecommendedQuizForMaterial(
          material: buildMaterial(
            slug: 'draf-konsep-dasar-plta',
            categorySlug: 'hydro',
          ),
          availableQuizzes: quizzes,
        );
        expect(res.isDirectTopicMatch, isTrue);
        expect(res.quiz?.id, '11111111-1111-4111-8111-111111111103');
      },
    );

    test('maps geothermal material to Hydro & Geothermal quiz (1103)', () {
      final res = LearningIntegrationHelper.resolveRecommendedQuizForMaterial(
        material: buildMaterial(
          slug: 'draf-konsep-dasar-pltp',
          categorySlug: 'geothermal',
        ),
        availableQuizzes: quizzes,
      );
      expect(res.isDirectTopicMatch, isTrue);
      expect(res.quiz?.id, '11111111-1111-4111-8111-111111111103');
    });

    test('maps bioenergy material to Bioenergy quiz (1104)', () {
      final res = LearningIntegrationHelper.resolveRecommendedQuizForMaterial(
        material: buildMaterial(
          slug: 'draf-konsep-dasar-bioenergi',
          categorySlug: 'bioenergy',
        ),
        availableQuizzes: quizzes,
      );
      expect(res.isDirectTopicMatch, isTrue);
      expect(res.quiz?.id, '11111111-1111-4111-8111-111111111104');
    });

    test(
      'maps baseload vs VRE material to Master Archipelago quiz (1105)',
      () {
        final res = LearningIntegrationHelper.resolveRecommendedQuizForMaterial(
          material: buildMaterial(
            slug: 'baseload-vs-intermiten-vre',
            categorySlug: 'geothermal',
          ),
          availableQuizzes: quizzes,
        );
        expect(res.isDirectTopicMatch, isTrue);
        expect(res.quiz?.id, '11111111-1111-4111-8111-111111111105');
      },
    );

    test(
      'maps BESS & Pumped Storage material to Solar/Wind/BESS quiz (1102)',
      () {
        final res = LearningIntegrationHelper.resolveRecommendedQuizForMaterial(
          material: buildMaterial(
            slug: 'teknologi-penyimpanan-energi-bess-pumped-storage',
            categorySlug: 'solar',
          ),
          availableQuizzes: quizzes,
        );
        expect(res.isDirectTopicMatch, isTrue);
        expect(res.quiz?.id, '11111111-1111-4111-8111-111111111102');
      },
    );

    test(
      'maps Smart Grid material to Master Archipelago & Smart Grid quiz (1105)',
      () {
        final res = LearningIntegrationHelper.resolveRecommendedQuizForMaterial(
          material: buildMaterial(
            slug: 'smart-grid-dan-elektrifikasi-kepulauan',
          ),
          availableQuizzes: quizzes,
        );
        expect(res.isDirectTopicMatch, isTrue);
        expect(res.quiz?.id, '11111111-1111-4111-8111-111111111105');
      },
    );

    test(
      'maps Module 9 environmental transition to Quiz 6 (1106) when Quiz 6 is available, and falls back cleanly otherwise',
      () {
        final directRes =
            LearningIntegrationHelper.resolveRecommendedQuizForMaterial(
              material: buildMaterial(
                slug: 'transisi-energi-dan-dampak-lingkungan',
                categorySlug: 'solar',
              ),
              availableQuizzes: quizzes,
            );
        expect(directRes.isDirectTopicMatch, isTrue);
        expect(directRes.quiz?.id, '11111111-1111-4111-8111-111111111106');

        final fallbackRes =
            LearningIntegrationHelper.resolveRecommendedQuizForMaterial(
              material: buildMaterial(
                slug: 'transisi-energi-dan-dampak-lingkungan',
                categorySlug: 'solar',
              ),
              availableQuizzes: quizzes
                  .where((q) => q.id != '11111111-1111-4111-8111-111111111106')
                  .toList(),
            );
        expect(fallbackRes.isDirectTopicMatch, isFalse);
        expect(fallbackRes.quiz, isNull);
      },
    );

    test('returns safe fallback when availableQuizzes is empty', () {
      final res = LearningIntegrationHelper.resolveRecommendedQuizForMaterial(
        material: buildMaterial(
          slug: 'draf-konsep-dasar-plts',
          categorySlug: 'solar',
        ),
        availableQuizzes: const [],
      );
      expect(res.isDirectTopicMatch, isFalse);
      expect(res.quiz, isNull);
    });
  });

  group('LearningIntegrationHelper - selectRelevantPlantsForMaterial', () {
    test('prioritizes operating status and exact coordinate precision', () {
      const testPlants = <PowerPlant>[
        PowerPlant(
          id: 'p-planned-approx',
          name: 'PLTS Rencana',
          categoryId: 'cat-solar',
          categorySlug: 'solar',
          province: 'Jawa Barat',
          latitude: -6.0,
          longitude: 107.0,
          capacityMw: 200,
          operationalStatus: 'planned',
          coordinatePrecision: 'approximate',
          sourceUrl: 'https://esdm.go.id',
        ),
        PowerPlant(
          id: 'p-op-approx',
          name: 'PLTS Operasi Perkiraan',
          categoryId: 'cat-solar',
          categorySlug: 'solar',
          province: 'Jawa Barat',
          latitude: -6.1,
          longitude: 107.1,
          capacityMw: 150,
          operationalStatus: 'operating',
          coordinatePrecision: 'approximate',
          sourceUrl: 'https://esdm.go.id',
        ),
        PowerPlant(
          id: 'p-op-exact',
          name: 'PLTS Terapung Cirata',
          categoryId: 'cat-solar',
          categorySlug: 'solar',
          province: 'Jawa Barat',
          latitude: -6.6997,
          longitude: 107.3547,
          capacityMw: 192,
          operationalStatus: 'operating',
          coordinatePrecision: 'exact',
          sourceUrl: 'https://esdm.go.id',
        ),
      ];

      final solarMaterial = DemoData.materials.firstWhere(
        (m) => m.slug == 'draf-konsep-dasar-plts',
      );
      final selected =
          LearningIntegrationHelper.selectRelevantPlantsForMaterial(
            material: solarMaterial,
            allPlants: testPlants,
            maxCount: 3,
          );

      expect(selected.length, 3);
      expect(selected.first.id, 'p-op-exact');
      expect(selected[1].id, 'p-op-approx');
      expect(selected[2].id, 'p-planned-approx');
    });
  });

  group('LearningIntegrationHelper - buildPlantEducationalContext', () {
    test(
      'uses non-generalizing phrasing and includes balanced benefits & challenges',
      () {
        const plant = PowerPlant(
          id: 'p-cirata',
          name: 'PLTS Terapung Cirata',
          categoryId: 'cat-solar',
          categorySlug: 'solar',
          province: 'Jawa Barat',
          latitude: -6.6997,
          longitude: 107.3547,
          capacityMw: 192,
          operationalStatus: 'operating',
          coordinatePrecision: 'exact',
        );
        final ctx = LearningIntegrationHelper.buildPlantEducationalContext(
          plant,
        );

        expect(ctx.capacityAndStatusExplanation, contains('192.00 MW'));
        expect(ctx.geographicReasonBody.toLowerCase(), contains('umumnya'));
        expect(
          ctx.operationalCharacteristicsBody.toLowerCase(),
          contains('umumnya'),
        );
        expect(ctx.environmentalBenefits, isNotEmpty);
        expect(ctx.environmentalChallenges, isNotEmpty);
        expect(ctx.referenceAttribution, contains('IPCC AR6 WGIII'));
      },
    );

    test(
      'returns curated plant-specific case study for flagship plants across 5 categories',
      () {
        const flagshipSamples = <({String name, String slug})>[
          (name: 'PLTS Terapung Cirata (Cirata Reservoir Solar Farm)', slug: 'solar'),
          (name: 'PLTS Ibu Kota Nusantara (Nusantara Sembcorp Solar Energi Power Plant)', slug: 'solar'),
          (name: 'PLTS Likupang (Minut Solar Farm)', slug: 'solar'),
          (name: 'PLTA Cirata', slug: 'hydro'),
          (name: 'PLTA Saguling', slug: 'hydro'),
          (name: 'PLTA Upper Cisokan Pumped Storage', slug: 'hydro'),
          (name: 'PLTP Kamojang', slug: 'geothermal'),
          (name: 'PLTP Sarulla', slug: 'geothermal'),
          (name: 'PLTP Dieng', slug: 'geothermal'),
          (name: 'PLTB Sidrap I', slug: 'wind'),
          (name: 'PLTB Tolo I', slug: 'wind'),
          (name: 'PLTBg Jangkang', slug: 'bioenergy'),
          (name: 'PLTBm Siantan', slug: 'bioenergy'),
        ];

        for (final sample in flagshipSamples) {
          final plant = PowerPlant(
            id: 'id-${sample.name}',
            name: sample.name,
            categoryId: 'cat-${sample.slug}',
            categorySlug: sample.slug,
            province: 'Indonesia',
            latitude: -6.0,
            longitude: 107.0,
            operationalStatus: 'operating',
          );
          final ctx = LearningIntegrationHelper.buildPlantEducationalContext(plant);
          expect(ctx.plantSpecificHighlight, isNotNull, reason: sample.name);
          expect(ctx.highlightSourceLabel, isNotNull, reason: sample.name);
        }

        const genericPlant = PowerPlant(
          id: 'id-generic',
          name: 'PLTA Contoh Non-Ikon',
          categoryId: 'cat-hydro',
          categorySlug: 'hydro',
          province: 'Jawa Timur',
          latitude: -8.0,
          longitude: 112.0,
          operationalStatus: 'operating',
        );
        final genericCtx = LearningIntegrationHelper.buildPlantEducationalContext(genericPlant);
        expect(genericCtx.plantSpecificHighlight, isNull);
      },
    );
  });

  group('Routing & Remedial Slug Integrity', () {
    test('energy comparison route path matches registered GoRouter path', () {
      expect(RouteNames.energyComparisonPath, '/energy-comparison');
    });

    test('remedialInfoForQuiz resolves all 6 quizzes to curated SQL slugs', () {
      const validCuratedSlugs = <String>{
        'draf-konsep-dasar-plts',
        'draf-konsep-dasar-plta',
        'draf-konsep-dasar-pltb',
        'draf-konsep-dasar-pltp',
        'draf-konsep-dasar-bioenergi',
        'baseload-vs-intermiten-vre',
        'teknologi-penyimpanan-energi-bess-pumped-storage',
        'smart-grid-dan-elektrifikasi-kepulauan',
        'transisi-energi-dan-dampak-lingkungan',
      };

      for (final quiz in DemoData.quizzes) {
        final remedial = LearningIntegrationHelper.remedialInfoForQuiz(quiz.id);
        expect(
          validCuratedSlugs.contains(remedial.materialSlug),
          isTrue,
          reason: 'Invalid remedial slug ${remedial.materialSlug} for ${quiz.id}',
        );
      }
    });
  });

  group('ReadingProgressNotifier - High-Water Mark Persistence', () {
    test(
      'keeps reading progress at highest percentage reached even when user scrolls back up',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(readingProgressProvider.notifier);

        await notifier.updateReadingProgress(
          slug: 'draf-konsep-dasar-plts',
          scrollFraction: 0.50,
          scrollOffset: 420.0,
        );
        expect(
          container
              .read(readingProgressProvider)
              .progressFor('draf-konsep-dasar-plts'),
          closeTo(0.50, 0.001),
        );

        // Pengguna scroll kembali ke atas (10%), progres TIDAK BOLEH turun dari 50%
        await notifier.updateReadingProgress(
          slug: 'draf-konsep-dasar-plts',
          scrollFraction: 0.10,
          scrollOffset: 80.0,
        );
        expect(
          container
              .read(readingProgressProvider)
              .progressFor('draf-konsep-dasar-plts'),
          closeTo(0.50, 0.001),
        );
        expect(
          container
              .read(readingProgressProvider)
              .lastOffsetFor('draf-konsep-dasar-plts'),
          closeTo(80.0, 0.001),
        );
      },
    );
  });

  group('Guest Mode & Pre/Post Quiz Score Delta', () {
    test('GuestModeNotifier toggles guest browsing session in memory', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(isGuestModeProvider), isFalse);
      container.read(isGuestModeProvider.notifier).enterGuestMode();
      expect(container.read(isGuestModeProvider), isTrue);
      container.read(isGuestModeProvider.notifier).exitGuestMode();
      expect(container.read(isGuestModeProvider), isFalse);
    });

    test('summarizeQuizAttempts computes baseline, latest, best, and delta', () {
      final attempts = <QuizAttempt>[
        // Urutan newest-first seperti query Supabase completed_at desc
        QuizAttempt(
          id: 'a3',
          userId: 'u1',
          quizId: 'q1',
          score: 90,
          correctCount: 9,
          totalQuestions: 10,
          completedAt: DateTime.utc(2026, 11, 16, 10, 30),
        ),
        QuizAttempt(
          id: 'a2',
          userId: 'u1',
          quizId: 'q1',
          score: 100,
          correctCount: 10,
          totalQuestions: 10,
          completedAt: DateTime.utc(2026, 11, 16, 10, 15),
        ),
        QuizAttempt(
          id: 'a1',
          userId: 'u1',
          quizId: 'q1',
          score: 50,
          correctCount: 5,
          totalQuestions: 10,
          completedAt: DateTime.utc(2026, 11, 16, 10, 0),
        ),
        QuizAttempt(
          id: 'b1',
          userId: 'u1',
          quizId: 'q2',
          score: 60,
          correctCount: 3,
          totalQuestions: 5,
          completedAt: DateTime.utc(2026, 11, 16, 11, 0),
        ),
      ];

      final summaries = summarizeQuizAttempts(attempts);
      final q1 = summaries['q1']!;
      expect(q1.attemptCount, 3);
      expect(q1.initialScore, 50);
      expect(q1.latestScore, 90);
      expect(q1.bestScore, 100);
      expect(q1.scoreDelta, 40);
      expect(q1.hasMultipleAttempts, isTrue);

      final q2 = summaries['q2']!;
      expect(q2.attemptCount, 1);
      expect(q2.initialScore, 60);
      expect(q2.latestScore, 60);
      expect(q2.scoreDelta, 0);
      expect(q2.hasMultipleAttempts, isFalse);
    });
  });
}
