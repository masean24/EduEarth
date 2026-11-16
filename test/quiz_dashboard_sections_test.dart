import 'package:eduearth/core/constants/demo_data.dart';
import 'package:eduearth/features/auth/presentation/providers/auth_provider.dart';
import 'package:eduearth/features/quiz/presentation/pages/quiz_dashboard_page.dart';
import 'package:eduearth/features/quiz/presentation/providers/quiz_providers.dart';
import 'package:eduearth/features/quiz/presentation/widgets/quiz_dashboard_sections.dart';
import 'package:eduearth/models/quiz.dart';
import 'package:eduearth/models/quiz_attempt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuizDashboardSections pure helpers', () {
    test('buildQuizFilterOptions includes status and active quiz categories', () {
      final options = buildQuizFilterOptions(DemoData.quizzes);
      expect(
        options,
        containsAllInOrder([
          'Semua',
          'Belum dikerjakan',
          'Selesai',
          'Surya',
          'Panas Bumi',
          'Bioenergi',
          'Lintas',
        ]),
      );
    });

    test('filterAndSortQuizzes prioritizes uncompleted quizzes first', () {
      final summaries = <String, QuizAttemptSummary>{
        DemoData.quizzes.first.id: QuizAttemptSummary(
          quizId: DemoData.quizzes.first.id,
          attemptCount: 2,
          initialScore: 60,
          bestScore: 100,
          latestScore: 100,
        ),
      };

      final sortedAll = filterAndSortQuizzes(
        quizzes: DemoData.quizzes,
        summaries: summaries,
        filterKey: 'Semua',
      );
      expect(sortedAll.first.id, isNot(DemoData.quizzes.first.id));
      expect(sortedAll.last.id, DemoData.quizzes.first.id);

      final solarOnly = filterAndSortQuizzes(
        quizzes: DemoData.quizzes,
        summaries: summaries,
        filterKey: 'Surya',
      );
      expect(solarOnly, hasLength(1));
      expect(solarOnly.first.categorySlug, 'solar');

      final completedOnly = filterAndSortQuizzes(
        quizzes: DemoData.quizzes,
        summaries: summaries,
        filterKey: 'Selesai',
      );
      expect(completedOnly, hasLength(1));
      expect(completedOnly.first.id, DemoData.quizzes.first.id);
    });

    test('groupQuizAttempts aggregates attempts and calculates bestScore', () {
      final q1 = DemoData.quizzes[0];
      final q2 = DemoData.quizzes[1];
      final attempts = <QuizAttempt>[
        QuizAttempt(
          id: 'att-1',
          userId: 'u1',
          quizId: q1.id,
          quizTitle: q1.title,
          score: 80,
          correctCount: 4,
          totalQuestions: 5,
          completedAt: DateTime(2026, 11, 17, 10),
        ),
        QuizAttempt(
          id: 'att-2',
          userId: 'u1',
          quizId: q1.id,
          quizTitle: q1.title,
          score: 100,
          correctCount: 5,
          totalQuestions: 5,
          completedAt: DateTime(2026, 11, 16, 10),
        ),
        QuizAttempt(
          id: 'att-3',
          userId: 'u1',
          quizId: q2.id,
          quizTitle: q2.title,
          score: 20,
          correctCount: 1,
          totalQuestions: 5,
          completedAt: DateTime(2026, 11, 15, 10),
        ),
      ];

      final groups = groupQuizAttempts(
        attempts: attempts,
        quizzes: DemoData.quizzes,
      );
      expect(groups, hasLength(2));
      expect(groups[0].quizId, q1.id);
      expect(groups[0].bestScore, 100);
      expect(groups[0].attempts, hasLength(2));
      expect(groups[1].bestScore, 20);
    });

    test('quizScoreTierForScore maps good, mid, and low tiers accurately', () {
      expect(quizScoreTierForScore(80).foregroundColor, QuizLightPalette.goodFg);
      expect(quizScoreTierForScore(60).foregroundColor, QuizLightPalette.midFg);
      expect(quizScoreTierForScore(20).foregroundColor, QuizLightPalette.lowFg);
    });

    test('formatQuizRelativeTime formats today, yesterday, and days ago', () {
      final now = DateTime(2026, 11, 17, 15, 0);
      expect(formatQuizRelativeTime(DateTime(2026, 11, 17, 8), now: now), 'Hari ini');
      expect(formatQuizRelativeTime(DateTime(2026, 11, 16, 20), now: now), 'Kemarin');
      expect(
        formatQuizRelativeTime(DateTime(2026, 11, 14, 12), now: now),
        '3 hari lalu',
      );
    });
  });

  group('QuizDashboardPage UI & Filter Interaction', () {
    Widget buildHarness({
      required bool isAuthenticated,
      required List<Quiz> quizzes,
      required List<QuizAttempt> attempts,
    }) {
      return ProviderScope(
        overrides: [
          isAuthenticatedProvider.overrideWith((ref) => isAuthenticated),
          publishedQuizzesProvider.overrideWith((ref) async => quizzes),
          userQuizAttemptsProvider.overrideWith((ref) async => attempts),
        ],
        child: const MaterialApp(
          home: QuizDashboardPage(),
        ),
      );
    }

    testWidgets('shows Light Mode summary card, category filter, and accordion history', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final q1 = DemoData.quizzes[0];
      final q2 = DemoData.quizzes[1];
      final attempts = <QuizAttempt>[
        QuizAttempt(
          id: 'a1',
          userId: 'u1',
          quizId: q1.id,
          quizTitle: q1.title,
          score: 100,
          correctCount: 5,
          totalQuestions: 5,
          completedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        buildHarness(
          isAuthenticated: true,
          quizzes: [q1, q2],
          attempts: attempts,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kuis Energi Terbarukan'), findsOneWidget);
      expect(find.text('1 dari 2 kuis selesai'), findsOneWidget);
      expect(find.text('Mulai kuis'), findsOneWidget);
      expect(find.text('Ulangi kuis'), findsOneWidget);

      // Pastikan halaman kuis bersih dari gradasi latar atau tombol gradien
      final decorations = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((d) => d.decoration)
          .whereType<BoxDecoration>();
      expect(
        decorations.any((d) => d.gradient != null),
        isFalse,
      );

      // Tap Info icon while header is at top of viewport
      await tester.tap(find.byTooltip('Info penilaian kuis'));
      await tester.pumpAndSettle();
      expect(find.text('Info Penilaian Kuis'), findsOneWidget);
      await tester.tap(find.text('Mengerti'));
      await tester.pumpAndSettle();

      // Scroll filter list horizontally until Surya chip is centered, then tap
      final chipsScrollable = find.descendant(
        of: find.byKey(const ValueKey<String>('quiz_filter_chips_list')),
        matching: find.byType(Scrollable),
      );
      final solarChip = find.byKey(
        const ValueKey<String>('quiz_filter_chip_Surya'),
      );
      await tester.scrollUntilVisible(
        solarChip,
        120,
        scrollable: chipsScrollable,
      );
      await tester.drag(
        find.byKey(const ValueKey<String>('quiz_filter_chips_list')),
        const Offset(-80, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(solarChip);
      await tester.pumpAndSettle();

      expect(find.text(q2.title), findsOneWidget);
      expect(find.text('Ulangi kuis'), findsNothing);

      // Accordion attempt row displays accuracy & detail trigger
      expect(find.text('Benar 5 dari 5'), findsOneWidget);
      expect(find.text('Detail'), findsOneWidget);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -240));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Detail'));
      await tester.pumpAndSettle();
      expect(find.text('Pelajari Materi'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    });

    testWidgets('shows honest Guest Mode state without persisted scores', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildHarness(
          isAuthenticated: false,
          quizzes: DemoData.quizzes.take(2).toList(),
          attempts: const [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mode tamu · 2 tantangan siap'), findsOneWidget);
      expect(find.text('Masuk untuk mulai kuis'), findsNWidgets(2));
    });
  });
}
