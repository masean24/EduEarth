import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common/category_chip.dart';
import '../../../../core/widgets/common/empty_view.dart';
import '../../../../core/widgets/common/error_view.dart';
import '../../../../core/widgets/common/loading_view.dart';
import '../../../../core/widgets/common/primary_button.dart';
import '../../../../core/widgets/common/screen_header.dart';
import '../../../../core/widgets/common/soft_image_placeholder.dart';
import '../../../../routes/route_names.dart';
import '../../../../services/external_map_service.dart';
import '../../../achievement/presentation/providers/achievement_providers.dart';
import '../../../achievement/presentation/widgets/achievement_unlock_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../bookmark/presentation/providers/bookmark_providers.dart';
import '../providers/learning_providers.dart';

/// Halaman Baca Materi Pembelajaran (Learning Detail) yang dilengkapi:
/// - Indikator progres baca (Reading Progress Bar) real-time saat di-scroll
/// - Render Markdown kaya (tabel terformat, kutipan/callout berbingkai hijau)
/// - Kartu Flashcard interaktif ("Uji Kilat Konsep") & ajakan ke halaman Kuis
class LearningDetailPage extends ConsumerStatefulWidget {
  const LearningDetailPage({
    super.key,
    required this.materialSlug,
  });

  final String materialSlug;

  @override
  ConsumerState<LearningDetailPage> createState() => _LearningDetailPageState();
}

class _LearningDetailPageState extends ConsumerState<LearningDetailPage> {
  final ScrollController _scrollController = ScrollController();
  double _readingProgress = 0.0;
  bool _isFlashcardRevealed = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) {
      if (_readingProgress != 1.0) {
        setState(() => _readingProgress = 1.0);
      }
      return;
    }
    final current = (_scrollController.offset / maxScroll).clamp(0.0, 1.0);
    if ((current - _readingProgress).abs() > 0.01) {
      setState(() => _readingProgress = current);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _handleOpenLink(
    BuildContext context,
    ExternalMapService externalMapService,
    String? href,
  ) async {
    if (href == null || href.trim().isEmpty) return;

    final uri = Uri.tryParse(href.trim());
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tautan tidak didukung atau tidak aman untuk dibuka.'),
          ),
        );
      }
      return;
    }

    final launched = await externalMapService.openExternalUrl(href);
    if (!context.mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membuka tautan referensi di browser.'),
        ),
      );
    }
  }

  Future<void> _handleToggleBookmark(
    BuildContext context,
    String materialId,
    bool currentlyBookmarked,
  ) async {
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masuk (login) untuk menyimpan bookmark.'),
        ),
      );
      context.push(RouteNames.loginPath);
      return;
    }

    final success = await ref
        .read(bookmarkControllerProvider.notifier)
        .toggleMaterial(materialId);

    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentlyBookmarked
                ? 'Materi dihapus dari Bookmark.'
                : 'Materi disimpan ke Bookmark.',
          ),
        ),
      );
      if (!currentlyBookmarked) {
        try {
          final award = await ref
              .read(achievementRepositoryProvider)
              .evaluateAchievements();
          ref.invalidate(achievementsListProvider);
          if (context.mounted && award.newlyAwardedTitles.isNotEmpty) {
            await showAchievementUnlockDialog(
              context,
              badgeTitles: award.newlyAwardedTitles,
            );
          }
        } catch (_) {}
      }
    } else {
      final err = ref.read(bookmarkControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err?.toString() ?? 'Gagal memperbarui bookmark.'),
        ),
      );
    }
  }

  ({String question, String answer}) _flashcardForCategory(String? slug) {
    switch (slug?.toLowerCase().trim()) {
      case 'solar':
        return (
          question:
              'Mengapa arus listrik dari modul surya harus melewati Inverter sebelum masuk ke jaringan rumah/PLN?',
          answer:
              'Karena sel fotovoltaik membangkitkan arus searah (DC), sedangkan jaringan listrik PLN dan peralatan rumah tangga beroperasi menggunakan arus bolak-balik (AC).',
        );
      case 'hydro':
        return (
          question:
              'Apa keunggulan utama PLTA berwaduk (reservoir) saat disandingkan dengan pembangkit surya atau angin?',
          answer:
              'Debit air dari waduk dapat diatur buka-tutupnya dengan sangat cepat sehingga mampu menstabilkan frekuensi jaringan ketika cuaca mendung atau beban malam melonjak.',
        );
      case 'wind':
        return (
          question:
              'Bagaimana cara sistem Pitch Control melindungi turbin angin saat terjadi angin badai?',
          answer:
              'Dengan memutar sudut kemiringan bilah (feathering) agar tidak menangkap gaya angkat berlebih sehingga putaran rotor tetap berada di batas aman.',
        );
      case 'geothermal':
        return (
          question:
              'Mengapa air kondensat dan brine pada PLTP wajib diinjeksikan kembali melalui sumur injeksi?',
          answer:
              'Untuk menjaga tekanan hidrotermal dan cadangan fluida di dalam reservoar bawah bumi agar pembangkit tetap lestari dalam jangka panjang.',
        );
      case 'bioenergy':
        return (
          question:
              'Apa perbedaan bahan baku dan proses antara PLTBm dan PLTBg?',
          answer:
              'PLTBm mengolah biomassa padat melalui pembakaran boiler/gasifikasi, sedangkan PLTBg memfermentasi limbah organik cair tanpa oksigen (anaerobik) menjadi gas metana.',
        );
      default:
        return (
          question:
              'Apa perbedaan mendasar antara pembangkit beban dasar (baseload) dan pembangkit intermiten (VRE)?',
          answer:
              'Pembangkit baseload (seperti PLTP) menyuplai daya stabil 24 jam, sedangkan pembangkit VRE (seperti PLTS & PLTB) berfluktuasi mengikuti kondisi cuaca alami.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final materialAsync = ref.watch(
      learningMaterialDetailProvider(widget.materialSlug),
    );
    final externalMapService = ref.watch(externalMapServiceProvider);
    final bookmarkController = ref.watch(bookmarkControllerProvider);

    return Scaffold(
      appBar: ScreenHeaderBar(
        title: 'Materi Pembelajaran',
        subtitle: materialAsync.asData != null
            ? shortDisplayLabelForSlug(
                materialAsync.asData!.value.categorySlug,
                'Konsep energi terbarukan',
              )
            : 'Konsep energi terbarukan',
        actions: [
          if (materialAsync.asData != null)
            Builder(
              builder: (context) {
                final material = materialAsync.asData!.value;
                final isBookmarked = ref.watch(
                  isMaterialBookmarkedProvider(material.id),
                );
                return ScreenHeaderAction(
                  tooltip: isBookmarked
                      ? 'Hapus dari Bookmark'
                      : 'Simpan ke Bookmark',
                  icon: isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  iconColor: isBookmarked
                      ? AppColors.freshGreen
                      : AppColors.forestGreen,
                  onTap: bookmarkController.isLoading
                      ? null
                      : () => _handleToggleBookmark(
                            context,
                            material.id,
                            isBookmarked,
                          ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: materialAsync.when(
          loading: () => const LoadingView(
            message: 'Memuat isi materi pembelajaran...',
          ),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(
              learningMaterialDetailProvider(widget.materialSlug),
            ),
          ),
          data: (material) {
            if (material.contentMd.trim().isEmpty) {
              return EmptyView(
                title: 'Konten Materi Kosong',
                description:
                    'Isi materi pembelajaran ini belum ditulis pada database.',
                actionLabel: 'Kembali',
                onAction: () => context.pop(),
              );
            }

            final categoryColor = AppColors.colorForCategorySlug(
              material.categorySlug ?? '',
            );
            final flashcard = _flashcardForCategory(material.categorySlug);
            final percentRead = (_readingProgress * 100).round();

            return Column(
              children: [
                // Bar Progres Baca Real-Time
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceWhite,
                    border: Border(
                      bottom: BorderSide(color: AppColors.divider),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_stories_outlined,
                        size: 15,
                        color: AppColors.forestGreen,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppTheme.pillRadius,
                          ),
                          child: LinearProgressIndicator(
                            value: _readingProgress.clamp(0.05, 1.0),
                            minHeight: 6,
                            backgroundColor: AppColors.offWhite,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.freshGreen,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$percentRead% dibaca',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
                    children: [
                      if (material.isDraft) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.warmYellow.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.warmYellow),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.edit_note_rounded,
                                color: AppColors.forestGreen,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Materi ini berstatus DRAF konsep dasar untuk direview.',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.forestGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Header kartu hero materi
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              categoryColor.withValues(alpha: 0.16),
                              AppColors.mintGreen.withValues(alpha: 0.55),
                              AppColors.surfaceWhite,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                            AppTheme.cardRadius,
                          ),
                          border: Border.all(color: AppColors.sageGreen),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceWhite,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.pillRadius,
                                    ),
                                    border: Border.all(color: categoryColor),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        iconForCategorySlug(
                                          material.categorySlug,
                                        ),
                                        size: 14,
                                        color: AppColors.forestGreen,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        shortDisplayLabelForSlug(
                                          material.categorySlug,
                                          'Energi Bersih',
                                        ),
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.forestGreen,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceWhite,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.pillRadius,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.schedule_rounded,
                                        size: 13,
                                        color: AppColors.forestGreen,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${material.readMinutes} mnt • ${material.difficultyLabel}',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.forestGreen,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              material.title,
                              style: AppTextStyles.display.copyWith(
                                fontSize: 21,
                                height: 1.28,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              material.summary,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Isi Artikel Markdown Terformat
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(
                            AppTheme.cardRadius,
                          ),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: MarkdownBody(
                          data: material.contentMd,
                          selectable: true,
                          onTapLink: (text, href, title) {
                            _handleOpenLink(context, externalMapService, href);
                          },
                          styleSheet: MarkdownStyleSheet(
                            h1: AppTextStyles.display.copyWith(fontSize: 21),
                            h2: AppTextStyles.title.copyWith(
                              fontSize: 17.5,
                              color: AppColors.forestGreen,
                            ),
                            h3: AppTextStyles.subtitle.copyWith(
                              fontSize: 15,
                              color: AppColors.forestGreen,
                            ),
                            p: AppTextStyles.body.copyWith(height: 1.65),
                            listBullet: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.forestGreen,
                            ),
                            strong: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.forestGreen,
                            ),
                            blockquotePadding: const EdgeInsets.all(14),
                            blockquoteDecoration: BoxDecoration(
                              color: AppColors.mintGreen.withValues(
                                alpha: 0.55,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: const Border(
                                left: BorderSide(
                                  color: AppColors.freshGreen,
                                  width: 4,
                                ),
                              ),
                            ),
                            tableHead: AppTextStyles.caption.copyWith(
                              color: AppColors.forestGreen,
                              fontWeight: FontWeight.w800,
                            ),
                            tableBody: AppTextStyles.caption.copyWith(
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                            tableCellsPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            tableBorder: TableBorder.all(
                              color: AppColors.divider,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            a: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.skyBlue,
                              decoration: TextDecoration.underline,
                            ),
                            horizontalRuleDecoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: AppColors.divider,
                                  width: 1,
                                ),
                              ),
                            ),
                            blockSpacing: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Flashcard Interaktif "Uji Kilat Konsep"
                      GestureDetector(
                        onTap: () {
                          setState(
                            () => _isFlashcardRevealed = !_isFlashcardRevealed,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: _isFlashcardRevealed
                                ? AppColors.mintGreen.withValues(alpha: 0.75)
                                : AppColors.surfaceWhite,
                            borderRadius: BorderRadius.circular(
                              AppTheme.cardRadius,
                            ),
                            border: Border.all(
                              color: _isFlashcardRevealed
                                  ? AppColors.freshGreen
                                  : AppColors.sageGreen,
                              width: 1.4,
                            ),
                            boxShadow: AppTheme.softCardShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _isFlashcardRevealed
                                          ? AppColors.forestGreen
                                          : const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _isFlashcardRevealed
                                          ? Icons.check_circle_outline_rounded
                                          : Icons.lightbulb_rounded,
                                      size: 18,
                                      color: _isFlashcardRevealed
                                          ? AppColors.surfaceWhite
                                          : const Color(0xFFD97706),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _isFlashcardRevealed
                                          ? 'Jawaban Konsep Kunci'
                                          : 'Flashcard: Uji Kilat Pemahamanmu!',
                                      style: AppTextStyles.subtitle.copyWith(
                                        fontSize: 15,
                                        color: AppColors.forestGreen,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceWhite,
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.pillRadius,
                                      ),
                                      border: Border.all(
                                        color: AppColors.divider,
                                      ),
                                    ),
                                    child: Text(
                                      _isFlashcardRevealed
                                          ? 'Tutup'
                                          : 'Ketuk Buka',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.forestGreen,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                flashcard.question,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.forestGreen,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (_isFlashcardRevealed) ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Divider(height: 1),
                                ),
                                Text(
                                  flashcard.answer,
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.forestGreen,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Kartu Ajakan ke Kuis Interaktif
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(
                            AppTheme.cardRadius,
                          ),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const SoftImagePlaceholder(
                                  width: 52,
                                  height: 52,
                                  borderRadius: 26,
                                  assetPath:
                                      'assets/images/mascot/eco_excited.png',
                                  backgroundColor: AppColors.mintGreen,
                                  fallbackIcon: Icons.emoji_events_rounded,
                                  iconColor: AppColors.forestGreen,
                                  iconSize: 26,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Siap Uji Wawasanmu?',
                                        style: AppTextStyles.subtitle.copyWith(
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Kerjakan kuis interaktif dan raih lencana pencapaian di profilmu!',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            PrimaryButton(
                              label: 'Lanjut ke Tantangan Kuis',
                              icon: Icons.quiz_rounded,
                              onPressed: () => context.go(RouteNames.quizPath),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
