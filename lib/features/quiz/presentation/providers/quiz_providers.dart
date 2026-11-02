import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/quiz.dart';
import '../../../../models/quiz_attempt.dart';
import '../../../../models/quiz_question.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
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
    required this.bestScore,
    required this.latestScore,
    this.latestCompletedAt,
  });

  final String quizId;
  final int attemptCount;
  final int bestScore;
  final int latestScore;
  final DateTime? latestCompletedAt;
}

/// Daftar seluruh kuis yang dipublikasikan.
final publishedQuizzesProvider = FutureProvider<List<Quiz>>((ref) async {
  final repo = ref.watch(quizRepositoryProvider);
  return repo.getPublishedQuizzes();
});

/// Detail kuis berdasarkan `quizId`.
final quizDetailProvider =
    FutureProvider.family<Quiz, String>((ref, quizId) async {
  final repo = ref.watch(quizRepositoryProvider);
  return repo.getQuizById(quizId);
});

/// Daftar soal untuk satu `quizId` (tanpa kunci jawaban).
final quizQuestionsProvider =
    FutureProvider.family<List<QuizQuestion>, String>((ref, quizId) async {
  final repo = ref.watch(quizRepositoryProvider);
  return repo.getQuestionsForQuiz(quizId);
});

/// Riwayat percobaan kuis milik pengguna yang sedang login (1 query untuk semua kuis,
/// terurut dari yang terbaru `completed_at desc`).
final userQuizAttemptsProvider =
    FutureProvider<List<QuizAttempt>>((ref) async {
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

  return attemptsAsync.whenData((attempts) {
    final grouped = <String, List<QuizAttempt>>{};
    for (final attempt in attempts) {
      grouped.putIfAbsent(attempt.quizId, () => <QuizAttempt>[]).add(attempt);
    }

    final summaries = <String, QuizAttemptSummary>{};
    grouped.forEach((quizId, list) {
      // Karena query sudah diurutkan completed_at desc, elemen pertama adalah skor terakhir
      final latest = list.first;
      var bestScore = latest.score;
      for (final item in list) {
        if (item.score > bestScore) {
          bestScore = item.score;
        }
      }

      summaries[quizId] = QuizAttemptSummary(
        quizId: quizId,
        attemptCount: list.length,
        bestScore: bestScore,
        latestScore: latest.score,
        latestCompletedAt: latest.completedAt,
      );
    });

    return summaries;
  });
});

/// Menyimpan hasil penilaian terakhir per `quizId` untuk ditampilkan di `QuizResultPage`.
class LatestQuizResultNotifier
    extends Notifier<Map<String, QuizSubmissionResult>> {
  @override
  Map<String, QuizSubmissionResult> build() =>
      const <String, QuizSubmissionResult>{};

  void setResult(String quizId, QuizSubmissionResult result) {
    state = {
      ...state,
      quizId: result,
    };
  }
}

final latestQuizResultProvider = NotifierProvider<
    LatestQuizResultNotifier,
    Map<String, QuizSubmissionResult>>(
  LatestQuizResultNotifier.new,
);

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
