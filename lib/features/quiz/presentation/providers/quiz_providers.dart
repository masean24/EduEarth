import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/learning_material.dart';
import '../../../../models/quiz.dart';
import '../../../../models/quiz_attempt.dart';
import '../../../../models/quiz_question.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../learning/domain/learning_integration_helper.dart';
import '../../data/quiz_repository.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return const QuizRepository();
});

/// Ringkasan statistik pengerjaan per kuis yang dikelompokkan di sisi client
/// dari satu query `userQuizAttemptsProvider`.
class QuizAttemptSummary {
  const QuizAttemptSummary({
    required this.quizId,
    required this.attemptCount,
    required this.initialScore,
    required this.bestScore,
    required this.latestScore,
    this.latestCompletedAt,
  });

  final String quizId;
  final int attemptCount;
  final int initialScore;
  final int bestScore;
  final int latestScore;
  final DateTime? latestCompletedAt;

  int get scoreDelta => latestScore - initialScore;
  bool get hasMultipleAttempts => attemptCount >= 2;
}

/// Mengelompokkan daftar riwayat kuis (terurut terbaru dahulu dari repository)
/// menjadi ringkasan skor awal (Pre-Check), skor terbaru, skor terbaik, & delta.
Map<String, QuizAttemptSummary> summarizeQuizAttempts(
  List<QuizAttempt> attempts,
) {
  final grouped = <String, List<QuizAttempt>>{};
  for (final attempt in attempts) {
    grouped.putIfAbsent(attempt.quizId, () => <QuizAttempt>[]).add(attempt);
  }

  final summaries = <String, QuizAttemptSummary>{};
  grouped.forEach((quizId, list) {
    // Urutkan kronologis dari yang paling awal; jika tanggal null/sama, anggap input newest-first
    final indexed = List.generate(list.length, (i) => (idx: i, item: list[i]));
    indexed.sort((a, b) {
      final at = a.item.completedAt;
      final bt = b.item.completedAt;
      if (at != null && bt != null) {
        final cmp = at.compareTo(bt);
        if (cmp != 0) return cmp;
      }
      // Fallback newest-first: indeks lebih besar berarti lebih awal
      return b.idx.compareTo(a.idx);
    });

    final earliest = indexed.first.item;
    final latest = indexed.last.item;
    var bestScore = latest.score;
    for (final entry in list) {
      if (entry.score > bestScore) {
        bestScore = entry.score;
      }
    }

    summaries[quizId] = QuizAttemptSummary(
      quizId: quizId,
      attemptCount: list.length,
      initialScore: earliest.score,
      bestScore: bestScore,
      latestScore: latest.score,
      latestCompletedAt: latest.completedAt,
    );
  });

  return summaries;
}

/// Daftar seluruh kuis yang dipublikasikan.
final publishedQuizzesProvider = FutureProvider<List<Quiz>>((ref) async {
  final repo = ref.watch(quizRepositoryProvider);
  return repo.getPublishedQuizzes();
});

/// Detail kuis berdasarkan `quizId`.
final quizDetailProvider = FutureProvider.family<Quiz, String>((
  ref,
  quizId,
) async {
  final repo = ref.watch(quizRepositoryProvider);
  return repo.getQuizById(quizId);
});

/// Provider Smart Quiz Resolver yang memetakan suatu [LearningMaterial]
/// ke [QuizRecommendationResult] berdasarkan kuis yang tersedia di database.
final recommendedQuizForMaterialProvider =
    Provider.family<AsyncValue<QuizRecommendationResult>, LearningMaterial>((
      ref,
      material,
    ) {
      final quizzesAsync = ref.watch(publishedQuizzesProvider);
      return quizzesAsync.whenData(
        (quizzes) =>
            LearningIntegrationHelper.resolveRecommendedQuizForMaterial(
              material: material,
              availableQuizzes: quizzes,
            ),
      );
    });

/// Daftar soal untuk satu `quizId` (tanpa kunci jawaban).
final quizQuestionsProvider = FutureProvider.family<List<QuizQuestion>, String>(
  (ref, quizId) async {
    final repo = ref.watch(quizRepositoryProvider);
    return repo.getQuestionsForQuiz(quizId);
  },
);

/// Riwayat percobaan kuis milik pengguna yang sedang login (1 query untuk semua kuis,
/// terurut dari yang terbaru `completed_at desc`).
final userQuizAttemptsProvider = FutureProvider<List<QuizAttempt>>((ref) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) {
    return const <QuizAttempt>[];
  }
  final repo = ref.watch(quizRepositoryProvider);
  return repo.getUserQuizAttempts();
});

/// Mengelompokkan hasil `userQuizAttemptsProvider` per `quizId` di sisi client
/// sehingga setiap kartu kuis di Quiz Dashboard dapat langsung menampilkan badge
/// "Selesai", skor terbaik, skor terakhir, dan jumlah percobaan tanpa query berulang.
final quizAttemptsByQuizIdProvider =
    Provider<AsyncValue<Map<String, QuizAttemptSummary>>>((ref) {
      final attemptsAsync = ref.watch(userQuizAttemptsProvider);
      return attemptsAsync.whenData(summarizeQuizAttempts);
    });

/// Menyimpan hasil penilaian terakhir per `quizId` untuk ditampilkan di `QuizResultPage`.
class LatestQuizResultNotifier
    extends Notifier<Map<String, QuizSubmissionResult>> {
  @override
  Map<String, QuizSubmissionResult> build() =>
      const <String, QuizSubmissionResult>{};

  void setResult(String quizId, QuizSubmissionResult result) {
    state = {...state, quizId: result};
  }
}

final latestQuizResultProvider =
    NotifierProvider<
      LatestQuizResultNotifier,
      Map<String, QuizSubmissionResult>
    >(LatestQuizResultNotifier.new);

/// Controller untuk mengirim jawaban kuis ke RPC `submit_quiz_attempt`.
class QuizSubmissionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<QuizSubmissionResult?> submit({
    required String quizId,
    required Map<String, String> answers,
  }) async {
    state = const AsyncLoading();
    final repo = ref.read(quizRepositoryProvider);
    QuizSubmissionResult? submissionResult;

    state = await AsyncValue.guard(() async {
      submissionResult = await repo.submitQuizAttempt(
        quizId: quizId,
        answers: answers,
      );
      if (submissionResult != null) {
        ref
            .read(latestQuizResultProvider.notifier)
            .setResult(quizId, submissionResult!);
        // Invalidate riwayat attempt agar Quiz Dashboard langsung terbarui
        ref.invalidate(userQuizAttemptsProvider);
      }
    });

    return submissionResult;
  }
}

final quizSubmissionControllerProvider =
    AsyncNotifierProvider<QuizSubmissionController, void>(
      QuizSubmissionController.new,
    );
