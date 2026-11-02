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
import '../../../../core/widgets/common/screen_header.dart';
import '../../../../routes/route_names.dart';
import '../../../../services/external_map_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../bookmark/presentation/providers/bookmark_providers.dart';
import '../providers/learning_providers.dart';

/// Halaman Baca Materi Pembelajaran (Learning Detail) yang merender Markdown
/// menggunakan `flutter_markdown_plus`, menangani tautan secara aman,
/// dan menyediakan tombol toggle Bookmark.
class LearningDetailPage extends ConsumerWidget {
  const LearningDetailPage({
    super.key,
    required this.materialSlug,
  });

  final String materialSlug;

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
    WidgetRef ref,
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
    } else {
      final err = ref.read(bookmarkControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err?.toString() ?? 'Gagal memperbarui bookmark.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialAsync = ref.watch(
      learningMaterialDetailProvider(materialSlug),
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
                            ref,
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
              learningMaterialDetailProvider(materialSlug),
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

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
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
                            'Materi ini berstatus DRAF konsep dasar untuk direview sebelum rilis produksi.',
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
                        color: categoryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(
                          AppTheme.pillRadius,
                        ),
                        border: Border.all(color: categoryColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            iconForCategorySlug(material.categorySlug),
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
                        color: AppColors.mintGreen,
                        borderRadius: BorderRadius.circular(
                          AppTheme.pillRadius,
                        ),
                      ),
                      child: Text(
                        '${material.readMinutes} menit baca • ${material.difficultyLabel}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(material.title, style: AppTextStyles.display),
                const SizedBox(height: 10),
                Text(
                  material.summary,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: MarkdownBody(
                    data: material.contentMd,
                    selectable: true,
                    onTapLink: (text, href, title) {
                      _handleOpenLink(context, externalMapService, href);
                    },
                    styleSheet: MarkdownStyleSheet(
                      h1: AppTextStyles.display.copyWith(fontSize: 22),
                      h2: AppTextStyles.title.copyWith(fontSize: 18),
                      h3: AppTextStyles.subtitle,
                      p: AppTextStyles.body.copyWith(height: 1.65),
                      listBullet: AppTextStyles.bodyMedium,
                      strong: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      a: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.skyBlue,
                        decoration: TextDecoration.underline,
                      ),
                      horizontalRuleDecoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.divider, width: 1),
                        ),
                      ),
                      blockSpacing: 14,
                    ),
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

