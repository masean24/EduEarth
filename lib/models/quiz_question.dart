/// Opsi pilihan jawaban tunggal pada soal kuis (`[{ "id": "a", "text": "..." }]`).
class QuizOption {
  const QuizOption({
    required this.id,
    required this.text,
  });

  final String id;
  final String text;

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      id: (json['id'] as String?) ?? '',
      text: (json['text'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
    };
  }
}

/// Model immutable untuk tabel `quiz_questions`.
///
/// Sesuai aturan keamanan, model ini TIDAK PERNAH memiliki field kunci jawaban benar.
class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.quizId,
    required this.question,
    required this.options,
    required this.explanation,
    this.sortOrder = 0,
  });

  final String id;
  final String quizId;
  final String question;
  final List<QuizOption> options;
  final String explanation;
  final int sortOrder;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final parsedOptions = rawOptions is List<dynamic>
        ? rawOptions
            .whereType<Map<String, dynamic>>()
            .map(QuizOption.fromJson)
            .toList()
        : const <QuizOption>[];

    return QuizQuestion(
      id: (json['id'] as String?) ?? '',
      quizId: (json['quiz_id'] as String?) ?? '',
      question: (json['question'] as String?) ?? '',
      options: parsedOptions,
      explanation: (json['explanation'] as String?) ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quiz_id': quizId,
      'question': question,
      'options': options.map((o) => o.toJson()).toList(),
      'explanation': explanation,
      'sort_order': sortOrder,
    };
  }
}

