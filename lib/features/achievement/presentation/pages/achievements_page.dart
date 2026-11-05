import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common/empty_view.dart';
import '../../../../core/widgets/common/error_view.dart';
import '../../../../core/widgets/common/loading_view.dart';
import '../../../../core/widgets/common/screen_header.dart';
import '../../../../core/widgets/common/soft_image_placeholder.dart';
import '../../../../models/achievement.dart';
import '../providers/achievement_providers.dart';

/// Halaman Pencapaian & Badge (Achievement) Fase 6 sesuai `docs/design/moodboard.png`.
class AchievementsPage extends ConsumerStatefulWidget {
  const AchievementsPage({super.key});

  @override
  ConsumerState<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends ConsumerState<AchievementsPage> {
  bool _isChecking = false;

  Future<void> _manualEvaluate() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    try {
      final result = await ref
          .read(achievementRepositoryProvider)
          .evaluateAchievements();
      ref.invalidate(achievementsListProvider);
      if (!mounted) return;

      final newlyCount = result.newlyAwardedTitles.length;
      final message = newlyCount > 0
          ? 'Selamat! Badge baru terbuka: ${result.newlyAwardedTitles.join(', ')}'
          : 'Progres pencapaian telah diperbarui (${result.totalUnlocked} badge terbuka).';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  static IconData _iconForCode(String iconName) {
    switch (iconName.toLowerCase().trim()) {
      case 'bookmark_added_rounded':
        return Icons.bookmark_added_rounded;
      case 'menu_book_rounded':
        return Icons.menu_book_rounded;
      case 'map_rounded':
        return Icons.map_rounded;
      case 'quiz_rounded':
        return Icons.quiz_rounded;
      case 'workspace_premium_rounded':
        return Icons.workspace_premium_rounded;
      case 'emoji_events_rounded':
      default:
        return Icons.emoji_events_rounded;
    }
  }

  static String _formatUnlockedDate(DateTime date) {
    final local = date.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final achievementsAsync = ref.watch(achievementsListProvider);

    return Scaffold(
      appBar: ScreenHeaderBar(
        title: 'Pencapaian & Badge',
        subtitle: 'Lencana eksplorasi energi bersih Anda',
        actions: [
          ScreenHeaderAction(
            tooltip: 'Periksa Progres Pencapaian',
            icon: _isChecking ? Icons.sync_rounded : Icons.refresh_rounded,
            onTap: _manualEvaluate,
          ),
        ],
      ),
      body: SafeArea(
        child: achievementsAsync.when(
          loading: () => const LoadingView(
            message: 'Memuat daftar pencapaian...',
          ),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(achievementsListProvider),
          ),
          data: (achievements) {
            if (achievements.isEmpty) {
              return EmptyView(
                title: 'Belum Ada Pencapaian',
                description:
                    'Daftar lencana pencapaian belum tersedia di server saat ini.',
                actionLabel: 'Muat Ulang',
                onAction: () => ref.invalidate(achievementsListProvider),
              );
            }

            final unlockedCount = achievements
                .where((a) => a.isUnlocked)
                .length;
            final totalCount = achievements.length;
            final progress = totalCount > 0 ? unlockedCount / totalCount : 0.0;

            return RefreshIndicator(
              color: AppColors.freshGreen,
              onRefresh: () async {
                ref.invalidate(achievementsListProvider);
                await ref.read(achievementsListProvider.future);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
                children: [
                  _buildHeroSummaryCard(
                    unlockedCount: unlockedCount,
                    totalCount: totalCount,
                    progress: progress,
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Daftar Lencana', style: AppTextStyles.title),
                      Text(
                        '$unlockedCount dari $totalCount terbuka',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...achievements.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildAchievementCard(item),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroSummaryCard({
    required int unlockedCount,
    required int totalCount,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFEF9C3),
            AppColors.mintGreen,
            Color(0xFFE0F2FE),
          ],
        ),
        border: Border.all(
          color: AppColors.sageGreen.withValues(alpha: 0.65),
        ),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SoftImagePlaceholder(
                width: 88,
                height: 88,
                borderRadius: 24,
                assetPath: 'assets/images/mascot/eco_congrats.png',
                backgroundColor: Colors.transparent,
                fallbackIcon: Icons.emoji_events_rounded,
                iconColor: AppColors.forestGreen,
                iconSize: 42,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: AppTheme.badgePadding,
                      decoration: AppTheme.badgeDecoration(
                        backgroundColor: AppColors.surfaceWhite,
                        borderColor: AppColors.warmYellow,
                      ),
                      child: Text(
                        'Koleksi Badge Eco 🏆',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$unlockedCount / $totalCount Badge Terbuka',
                      style: AppTextStyles.display.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Selesaikan kuis dan simpan materi atau pembangkit untuk membuka seluruh lencana.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.surfaceWhite.withValues(alpha: 0.8),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.forestGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement item) {
    final isUnlocked = item.isUnlocked;
    return Container(
      padding: AppTheme.cardPadding,
      decoration: AppTheme.cardDecoration(
        backgroundColor:
            isUnlocked ? AppColors.surfaceWhite : const Color(0xFFF3F6F3),
        borderColor: isUnlocked
            ? AppColors.sageGreen.withValues(alpha: 0.8)
            : AppColors.divider,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isUnlocked
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFDE047),
                        Color(0xFFF59E0B),
                      ],
                    )
                  : null,
              color: isUnlocked ? null : AppColors.divider,
              border: Border.all(
                color: isUnlocked
                    ? const Color(0xFFD97706)
                    : AppColors.sageGreen.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Icon(
              _iconForCode(item.icon),
              color: isUnlocked ? AppColors.surfaceWhite : AppColors.textMuted,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: AppTextStyles.subtitle.copyWith(
                          color: isUnlocked
                              ? AppColors.forestGreen
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: AppTheme.badgePadding,
                      decoration: AppTheme.badgeDecoration(
                        backgroundColor: isUnlocked
                            ? AppColors.mintGreen
                            : AppColors.offWhite,
                        borderColor: isUnlocked
                            ? AppColors.freshGreen.withValues(alpha: 0.5)
                            : AppColors.divider,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isUnlocked
                                ? Icons.check_circle_rounded
                                : Icons.lock_outline_rounded,
                            size: 12,
                            color: isUnlocked
                                ? AppColors.forestGreen
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isUnlocked ? 'Terbuka' : 'Terkunci',
                            style: AppTextStyles.caption.copyWith(
                              color: isUnlocked
                                  ? AppColors.forestGreen
                                  : AppColors.textMuted,
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                  ),
                ),
                if (isUnlocked && item.unlockedAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Diraih pada ${_formatUnlockedDate(item.unlockedAt!)}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.forestGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
