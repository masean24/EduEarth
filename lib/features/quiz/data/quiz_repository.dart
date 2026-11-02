import '../../../core/config/app_config.dart';
import '../../../core/constants/demo_data.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../models/quiz.dart';
import '../../../models/quiz_attempt.dart';
import '../../../models/quiz_question.dart';
import '../../../services/supabase_service.dart';

/// Repository untuk membaca kuis, soal kuis (tanpa kunci jawaban),
/// men-submit jawaban melalui RPC `submit_quiz_attempt`, dan membaca riwayat
/// percobaan milik pengguna.
class QuizRepository {
  const QuizRepository();

  Future<List<Quiz>> getPublishedQuizzes() async {
    if (!AppConfig.isSupabaseConfigured) {
      return DemoData.quizzes;
    }

    try {
      final rows = await SupabaseService.client
          .from('quizzes')
          .select(
            '*, energy_categories(slug, name, short_code)',
          )
          .eq('is_published', true)
          .order('created_at', ascending: true);

      return (rows as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(Quiz.fromJson)
          .toList();
    } catch (e, st) {
      throw ErrorMapper.map(e, st);
    }
  }

  Future<Quiz> getQuizById(String quizId) async {
    if (!AppConfig.isSupabaseConfigured) {
      final match = DemoData.quizzes.where((q) => q.id == quizId).firstOrNull;
      if (match != null) return match;
      throw const AppException(
        message: 'Kuis tidak ditemukan.',
        code: 'not_found',
      );
    }

    try {
      final row = await SupabaseService.client
          .from('quizzes')
          .select(
            '*, energy_categories(slug, name, short_code)',
          )
          .eq('id', quizId)
          .eq('is_published', true)
          .maybeSingle();

      if (row == null) {
        throw const AppException(
          message: 'Kuis tidak ditemukan atau belum dipublikasikan.',
          code: 'not_found',
        );
      }

      return Quiz.fromJson(row);
    } catch (e, st) {
      throw ErrorMapper.map(e, st);
    }
  }

  Future<List<QuizQuestion>> getQuestionsForQuiz(String quizId) async {
    if (!AppConfig.isSupabaseConfigured) {
      return DemoData.quizQuestions
          .where((q) => q.quizId == quizId)
          .toList();
    }

    try {
      final rows = await SupabaseService.client
          .from('quiz_questions')
          .select('id, quiz_id, question, options, explanation, sort_order')
          .eq('quiz_id', quizId)
          .order('sort_order', ascending: true);

      return (rows as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(QuizQuestion.fromJson)
          .toList();
    } catch (e, st) {
      throw ErrorMapper.map(e, st);
    }
  }

  /// Men-submit jawaban kuis ke server lewat RPC `submit_quiz_attempt`.
  ///
  /// Client TIDAK PERNAH menilai jawaban sendiri dan TIDAK PERNAH menyimpan
  /// kunci jawaban di dalam kode aplikasi.
  Future<QuizSubmissionResult> submitQuizAttempt({
    required String quizId,
    required Map<String, String> answers,
  }) async {
    if (!AppConfig.isSupabaseConfigured) {
      throw const AppException(
        message:
            'Penilaian kuis wajib dilakukan di sisi server Supabase (RPC submit_quiz_attempt) karena kunci jawaban tidak disimpan di perangkat client.',
        code: 'server_required_for_quiz_grading',
      );
    }

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        throw const AppException(
          message:
              'Silakan masuk (login) terlebih dahulu untuk mengerjakan dan mengirim kuis.',
          code: 'unauthenticated',
        );
      }

      final response = await SupabaseService.client.rpc(
        'submit_quiz_attempt',
        params: {
          'p_quiz_id': quizId,
          'p_answers': answers,
        },
      );

      if (response is! Map<String, dynamic>) {
        throw const AppException(
          message: 'Format respons penilaian dari server tidak dikenali.',
          code: 'invalid_rpc_response',
        );
      }

      return QuizSubmissionResult.fromJson(response);
    } catch (e, st) {
      throw ErrorMapper.map(e, st);
    }
  }

  Future<List<QuizAttempt>> getUserQuizAttempts() async {
    if (!AppConfig.isSupabaseConfigured) {
      return const <QuizAttempt>[];
    }

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        return const <QuizAttempt>[];
      }

      final rows = await SupabaseService.client
          .from('quiz_attempts')
          .select('*, quizzes(title)')
          .eq('user_id', user.id)
          .order('completed_at', ascending: false);

      return (rows as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(QuizAttempt.fromJson)
          .toList();
    } catch (e, st) {
      throw ErrorMapper.map(e, st);
    }
  }
}
