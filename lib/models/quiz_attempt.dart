import 'quiz_question.dart';

/// Detail ulasan per soal yang dikembalikan oleh server (RPC `submit_quiz_attempt`)
/// HANYA setelah pengguna selesai men-submit kuis.
class QuizQuestionReview {
  const QuizQuestionReview({
    required this.questionId,
    required this.question,
    required this.options,
    required this.correctOptionId,
    required this.isCorrect,
    required this.explanation,
    this.selectedOptionId,
  });

  final String questionId;
  final String question;
  final List<QuizOption> options;
  final String? selectedOptionId;
  final String correctOptionId;
  final bool isCorrect;
  final String explanation;

  factory QuizQuestionReview.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final parsedOptions = rawOptions is List<dynamic>
        ? rawOptions
            .whereType<Map<String, dynamic>>()
            .map(QuizOption.fromJson)
            .toList()
        : const <QuizOption>[];

    return QuizQuestionReview(
      questionId: (json['question_id'] as String?) ?? '',
      question: (json['question'] as String?) ?? '',
      options: parsedOptions,
      selectedOptionId: json['selected_option_id'] as String?,
      correctOptionId: (json['correct_option_id'] as String?) ?? '',
      isCorrect: (json['is_correct'] as bool?) ?? false,
      explanation: (json['explanation'] as String?) ?? '',
    );
  }
}

/// Hasil evaluasi RPC `submit_quiz_attempt` dari server.
class QuizSubmissionResult {
  const QuizSubmissionResult({
    required this.attemptId,
    required this.quizId,
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
    required this.reviews,
    this.completedAt,
  });

  final String attemptId;
  final String quizId;
  final int score;
  final int correctCount;
  final int totalQuestions;
  final DateTime? completedAt;
  final List<QuizQuestionReview> reviews;

  factory QuizSubmissionResult.fromJson(Map<String, dynamic> json) {
    final rawReviews = json['reviews'];
    final parsedReviews = rawReviews is List<dynamic>
        ? rawReviews
            .whereType<Map<String, dynamic>>()
            .map(QuizQuestionReview.fromJson)
            .toList()
        : const <QuizQuestionReview>[];

    return QuizSubmissionResult(
      attemptId: (json['attempt_id'] as String?) ?? '',
      quizId: (json['quiz_id'] as String?) ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      correctCount: (json['correct_count'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 0,
      completedAt: _parseDate(json['completed_at']),
      reviews: parsedReviews,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

/// Model immutable untuk tabel `quiz_attempts` (riwayat pengerjaan kuis milik user).
class QuizAttempt {
  const QuizAttempt({
    required this.id,
    required this.userId,
    required this.quizId,
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
    this.quizTitle,
    this.answers = const <String, String>{},
    this.startedAt,
    this.completedAt,
  });

  final String id;
  final String userId;
  final String quizId;
  final String? quizTitle;
  final int score;
  final int correctCount;
  final int totalQuestions;
  final Map<String, String> answers;
  final DateTime? startedAt;
  final DateTime? completedAt;

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    final nestedQuiz = json['quizzes'];
    String? title = json['quiz_title'] as String?;
    if (nestedQuiz is Map<String, dynamic>) {
      title ??= nestedQuiz['title'] as String?;
    }

    final rawAnswers = json['answers'];
    final parsedAnswers = <String, String>{};
    if (rawAnswers is Map<String, dynamic>) {
      rawAnswers.forEach((key, value) {
        if (value is String) {
          parsedAnswers[key] = value;
        }
      });
    }

    return QuizAttempt(
      id: (json['id'] as String?) ?? '',
      userId: (json['user_id'] as String?) ?? '',
      quizId: (json['quiz_id'] as String?) ?? '',
      quizTitle: title,
      score: (json['score'] as num?)?.toInt() ?? 0,
      correctCount: (json['correct_count'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 0,
      answers: parsedAnswers,
      startedAt: _parseDate(json['started_at']),
      completedAt: _parseDate(json['completed_at']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
