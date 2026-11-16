import 'package:eduearth/core/constants/demo_data.dart';
import 'package:eduearth/features/achievement/presentation/providers/achievement_providers.dart';
import 'package:eduearth/features/auth/presentation/providers/auth_provider.dart';
import 'package:eduearth/features/bookmark/presentation/providers/bookmark_providers.dart';
import 'package:eduearth/features/learning/presentation/providers/learning_providers.dart';
import 'package:eduearth/features/learning/presentation/providers/reading_progress_provider.dart';
import 'package:eduearth/features/notification/presentation/providers/notification_providers.dart';
import 'package:eduearth/features/profile/presentation/pages/profile_page.dart';
import 'package:eduearth/features/profile/presentation/widgets/profile_sections.dart';
import 'package:eduearth/features/quiz/presentation/providers/quiz_providers.dart';
import 'package:eduearth/models/achievement.dart';
import 'package:eduearth/models/bookmark.dart';
import 'package:eduearth/models/learning_material.dart';
import 'package:eduearth/models/quiz.dart';
import 'package:eduearth/models/quiz_attempt.dart';
import 'package:eduearth/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _TestReadingProgressNotifier extends ReadingProgressNotifier {
  _TestReadingProgressNotifier(this._initialState);

  final ReadingProgressState _initialState;

  @override
  ReadingProgressState build() => _initialState;
}

void main() {
  group('ProfileSections pure helpers', () {
    test('computeProfileExplorerRankLabel maps badge count thresholds cleanly', () {
      expect(computeProfileExplorerRankLabel(0), '🌱 Penjelajah Energi');
      expect(computeProfileExplorerRankLabel(2), '🌿 Duta Energi Bersih');
      expect(computeProfileExplorerRankLabel(5), '⚡ Ahli Transisi Nusantara');
      expect(computeProfileExplorerRankLabel(9), '🏆 Master EduEarth');
    });

    test('computeTotalPossibleBadgePoints sums achievement points', () {
      expect(computeTotalPossibleBadgePoints(const []), 0);
      expect(
        computeTotalPossibleBadgePoints(DemoData.achievements),
        365,
      );
    });

    test('resolveProfileContinueTarget prioritizes in-progress reading, then quiz, then unread', () {
      const m1 = LearningMaterial(
        id: 'm1',
        categoryId: 'cat-1',
        title: 'Energi Surya (PLTS)',
        slug: 'energi-surya-plts',
        summary: 'Ringkasan',
        contentMd: '# Isi',
      );
      const m2 = LearningMaterial(
        id: 'm2',
        categoryId: 'cat-2',
        title: 'Energi Panas Bumi',
        slug: 'energi-panas-bumi',
        summary: 'Ringkasan',
        contentMd: '# Isi',
      );
      final quizzes = DemoData.quizzes.take(2).toList();

      // 1. In-progress reading material takes top priority
      final targetReading = resolveProfileContinueTarget(
        materials: const [m1, m2],
        readingState: const ReadingProgressState(
          maxProgressBySlug: {'energi-surya-plts': 0.45},
          lastReadSlug: 'energi-surya-plts',
          isLoaded: true,
        ),
        quizzes: quizzes,
        quizSummaries: const {},
      );
      expect(targetReading.overline, 'Lanjutkan membaca (45%)');
      expect(targetReading.title, 'Energi Surya (PLTS)');
      expect(targetReading.routePath, '/learning/material/energi-surya-plts');

      // 2. Next unattempted quiz when materials are read or none in progress
      final targetQuiz = resolveProfileContinueTarget(
        materials: const [m1],
        readingState: const ReadingProgressState(
          maxProgressBySlug: {'energi-surya-plts': 1.0},
          isLoaded: true,
        ),
        quizzes: quizzes,
        quizSummaries: {
          quizzes.first.id: QuizAttemptSummary(
            quizId: quizzes.first.id,
            attemptCount: 1,
            initialScore: 90,
            bestScore: 90,
            latestScore: 90,
          ),
        },
      );
      expect(targetQuiz.overline, 'Lanjutkan belajar');
      expect(targetQuiz.title, '${quizzes[1].title} belum dikerjakan');
      expect(targetQuiz.routePath, '/quiz/${quizzes[1].id}/play');

      // 3. Unread material when all quizzes are completed
      final completedQuizzes = <String, QuizAttemptSummary>{
        for (final q in quizzes)
          q.id: QuizAttemptSummary(
            quizId: q.id,
            attemptCount: 1,
            initialScore: 100,
            bestScore: 100,
            latestScore: 100,
          ),
      };
      final targetUnread = resolveProfileContinueTarget(
        materials: const [m1, m2],
        readingState: const ReadingProgressState(
          maxProgressBySlug: {'energi-surya-plts': 1.0},
          isLoaded: true,
        ),
        quizzes: quizzes,
        quizSummaries: completedQuizzes,
      );
      expect(targetUnread.overline, 'Mulai eksplorasi materi');
      expect(targetUnread.title, 'Energi Panas Bumi');

      // 4. Fallback summary link when everything is done
      final targetDone = resolveProfileContinueTarget(
        materials: const [m1],
        readingState: const ReadingProgressState(
          maxProgressBySlug: {'energi-surya-plts': 0.9},
          isLoaded: true,
        ),
        quizzes: quizzes,
        quizSummaries: completedQuizzes,
      );
      expect(targetDone.title, 'Lihat Progres Belajar & Skor');
    });
  });

  group('ProfilePage UI & Interactions', () {
    Session buildMockSession() {
      return Session(
        accessToken: 'test-token',
        tokenType: 'bearer',
        user: const User(
          id: 'user-1',
          appMetadata: <String, dynamic>{},
          userMetadata: <String, dynamic>{},
          aud: 'authenticated',
          createdAt: '2026-01-01T00:00:00Z',
          email: 'eans@gmail.com',
        ),
      );
    }

    Widget buildProfileHarness({
      required Session? session,
      UserProfile? profile,
      List<Bookmark> bookmarks = const [],
      List<QuizAttempt> attempts = const [],
      List<Achievement> achievements = const [],
      List<Quiz> quizzes = const [],
      ReadingProgressState readingState = const ReadingProgressState(isLoaded: true),
    }) {
      return ProviderScope(
        overrides: [
          currentSessionProvider.overrideWith((ref) => session),
          currentUserProfileProvider.overrideWith((ref) async => profile),
          userBookmarksProvider.overrideWith((ref) async => bookmarks),
          userQuizAttemptsProvider.overrideWith((ref) async => attempts),
          achievementsListProvider.overrideWith((ref) async => achievements),
          publishedQuizzesProvider.overrideWith((ref) async => quizzes),
          allLearningMaterialsProvider.overrideWith((ref) async => const []),
          readingProgressProvider.overrideWith(
            () => _TestReadingProgressNotifier(readingState),
          ),
          unreadNotificationsCountProvider.overrideWith((ref) => 1),
        ],
        child: const MaterialApp(
          home: ProfilePage(),
        ),
      );
    }

    testWidgets('renders clean Light Mode Profile layout with real stats & dialogs', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final unlockedFirst = DemoData.achievements.first.copyWith(
        unlockedAt: DateTime(2026, 11, 10),
      );
      final lockedSecond = DemoData.achievements[1];

      final bookmarks = <Bookmark>[
        const Bookmark(id: 'b1', userId: 'user-1', materialId: 'm1'),
        const Bookmark(id: 'b2', userId: 'user-1', plantId: 'p1'),
      ];
      final quizzes = DemoData.quizzes.take(2).toList();

      await tester.pumpWidget(
        buildProfileHarness(
          session: buildMockSession(),
          profile: const UserProfile(id: 'user-1', displayName: 'eans'),
          bookmarks: bookmarks,
          achievements: [unlockedFirst, lockedSecond],
          quizzes: quizzes,
          readingState: const ReadingProgressState(
            maxProgressBySlug: {'energi-surya-plts': 0.9},
            isLoaded: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header & hero info
      expect(find.text('Profil Saya'), findsOneWidget);
      expect(find.text('eans'), findsOneWidget);
      expect(find.text('eans@gmail.com'), findsOneWidget);
      expect(find.text('10 / 30 poin'), findsOneWidget);

      // 4 stats strip inside hero card
      expect(
        find.descendant(
          of: find.byType(ProfileHeroCard),
          matching: find.text('Tersimpan'),
        ),
        findsOneWidget,
      );
      expect(find.text('Percobaan'), findsOneWidget);
      expect(find.text('Dibaca'), findsOneWidget);
      expect(find.text('Badge'), findsOneWidget);

      // Continue banner picks unattempted quiz
      expect(find.text('Lanjutkan belajar'), findsOneWidget);
      expect(
        find.text('${quizzes.first.title} belum dikerjakan'),
        findsOneWidget,
      );

      // Badge showcase (1 unlocked, 1 locked)
      expect(find.text('Etalase lencana'), findsOneWidget);
      expect(find.text('1/2 terbuka'), findsOneWidget);
      expect(find.text(unlockedFirst.title), findsOneWidget);
      expect(find.text(lockedSecond.title), findsOneWidget);

      // Tapping locked badge shows hint snackbar, then dismiss it cleanly
      await tester.tap(find.text(lockedSecond.title));
      await tester.pumpAndSettle();
      expect(
        find.text('Terkunci: ${lockedSecond.description}'),
        findsOneWidget,
      );
      ScaffoldMessenger.of(
        tester.element(find.byType(ProfilePage)),
      ).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      // Scroll down to "Belajar & progres" section and 2x2 Bento tiles
      final mainScrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Belajar & progres'),
        120,
        scrollable: mainScrollable,
      );
      await tester.pumpAndSettle();
      expect(find.text('Belajar & progres'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Pusat Informasi'),
        120,
        scrollable: mainScrollable,
      );
      await tester.pumpAndSettle();

      expect(find.text('Progres & Skor'), findsOneWidget);
      expect(find.text('Bandingkan 5 Energi'), findsOneWidget);
      expect(find.text('Tersimpan'), findsAtLeastNWidgets(1));
      expect(find.text('2 materi & pembangkit favorit'), findsOneWidget);
      expect(find.text('Pusat Informasi'), findsOneWidget);
      expect(find.text('1 baru'), findsOneWidget);

      // Scroll further down to menu & sign out button
      await tester.scrollUntilVisible(
        find.text('Akun & pengaturan'),
        120,
        scrollable: mainScrollable,
      );
      await tester.pumpAndSettle();
      expect(find.text('Akun & pengaturan'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Keluar akun'),
        120,
        scrollable: mainScrollable,
      );
      await tester.pumpAndSettle();

      expect(find.text('Ubah profil'), findsOneWidget);
      expect(find.text('Pengaturan aplikasi'), findsOneWidget);
      expect(find.text('Tentang EduEarth'), findsOneWidget);

      await tester.tap(find.text('Keluar akun'));
      await tester.pumpAndSettle();
      expect(find.text('Keluar dari akun?'), findsOneWidget);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(find.text('Keluar dari akun?'), findsNothing);
    });

    testWidgets('renders clean Guest Mode layout when session is null', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildProfileHarness(session: null),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mode Tamu Aktif'), findsOneWidget);
      expect(find.text('Masuk / Daftar Akun'), findsOneWidget);
      expect(find.text('Jelajahi tanpa akun'), findsOneWidget);
    });

    testWidgets('handles narrow 360dp width and 1.2x text scaling without overflow', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 780),
            textScaler: TextScaler.linear(1.2),
          ),
          child: buildProfileHarness(
            session: buildMockSession(),
            profile: const UserProfile(
              id: 'user-1',
              displayName: 'Penjelajah Nusantara Sangat Panjang',
            ),
            achievements: DemoData.achievements.take(4).toList(),
            quizzes: DemoData.quizzes.take(2).toList(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Keluar akun'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Keluar akun'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
