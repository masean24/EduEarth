import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common/empty_view.dart';
import '../../../../core/widgets/common/error_view.dart';
import '../../../../core/widgets/common/loading_view.dart';
import '../../../../core/widgets/common/screen_header.dart';
import '../../../../models/app_notification.dart';
import '../providers/notification_providers.dart';

/// Halaman Notification Center (Pusat Informasi) Fase 6.
///
/// Menampilkan pengumuman publik (`is_published = true`) dari tabel `notifications`
/// dan mencatat waktu baca terakhir secara lokal di `SharedPreferences`.
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  DateTime? _initialLastReadSnapshot;
  bool _hasCapturedSnapshot = false;
  bool _hasMarkedReadOnOpen = false;

  void _syncReadTimestamp(List<AppNotification> items, DateTime? lastRead) {
    if (!_hasCapturedSnapshot) {
      _initialLastReadSnapshot = lastRead;
      _hasCapturedSnapshot = true;
    }
    if (_hasMarkedReadOnOpen || items.isEmpty) return;

    _hasMarkedReadOnOpen = true;
    final latestCreatedAt = items
        .map((e) => e.createdAt.toUtc())
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final nowUtc = DateTime.now().toUtc();
    final targetTimestamp =
        latestCreatedAt.isAfter(nowUtc) ? latestCreatedAt : nowUtc;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(lastReadNotificationsAtProvider.notifier)
          .markAsReadUpTo(targetTimestamp);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsListProvider);
    final lastReadAsync = ref.watch(lastReadNotificationsAtProvider);

    return Scaffold(
      appBar: ScreenHeaderBar(
        title: 'Pusat Informasi',
        subtitle: 'Pengumuman publik & pembaruan EduEarth',
        actions: [
          ScreenHeaderAction(
            icon: Icons.refresh_rounded,
            tooltip: 'Muat Ulang Pengumuman',
            onTap: () {
              _hasMarkedReadOnOpen = false;
              ref.invalidate(notificationsListProvider);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: notificationsAsync.when(
          loading: () => const LoadingView(
            message: 'Memuat daftar pengumuman...',
          ),
          error: (error, _) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(notificationsListProvider),
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return EmptyView(
                title: 'Belum Ada Pengumuman',
                description:
                    'Saat ini belum ada pengumuman publik terbaru dari EduEarth.',
                actionLabel: 'Muat Ulang',
                onAction: () => ref.invalidate(notificationsListProvider),
              );
            }

            if (!lastReadAsync.isLoading) {
              _syncReadTimestamp(notifications, lastReadAsync.asData?.value);
            }

            return RefreshIndicator(
              color: AppColors.freshGreen,
              onRefresh: () async {
                _hasMarkedReadOnOpen = false;
                ref.invalidate(notificationsListProvider);
                await ref.read(notificationsListProvider.future);
              },
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                itemCount: notifications.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = notifications[index];
                  final isUnreadInSnapshot = _initialLastReadSnapshot == null ||
                      item.createdAt
                          .toUtc()
                          .isAfter(_initialLastReadSnapshot!.toUtc());
                  return _buildNotificationCard(
                    item: item,
                    isUnread: isUnreadInSnapshot,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required AppNotification item,
    required bool isUnread,
  }) {
    final cleanTitle = item.title
        .replaceAll(RegExp(r'^\[CONTOH\]\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^\[DEMO\]\s*', caseSensitive: false), '')
        .trim();

    return Container(
      padding: AppTheme.cardPadding,
      decoration: AppTheme.cardDecoration(
        borderColor: isUnread
            ? AppColors.sageGreen.withValues(alpha: 0.9)
            : AppColors.divider,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.mintGreen,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.sageGreen.withValues(alpha: 0.6),
                  ),
                ),
                child: Icon(
                  _iconForCategory(item.category),
                  color: AppColors.forestGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildBadge(
                      label: _labelForCategory(item.category),
                      backgroundColor: AppColors.mintGreen,
                      textColor: AppColors.forestGreen,
                    ),
                    if (item.isExample)
                      _buildBadge(
                        label: 'CONTOH',
                        backgroundColor:
                            AppColors.warmYellow.withValues(alpha: 0.18),
                        textColor: const Color(0xFFB45309),
                      ),
                    if (isUnread)
                      _buildBadge(
                        label: 'BARU',
                        backgroundColor:
                            AppColors.freshGreen.withValues(alpha: 0.16),
                        textColor: AppColors.forestGreen,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(item.createdAt),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            cleanTitle.isEmpty ? item.title : cleanTitle,
            style: AppTextStyles.subtitle.copyWith(fontSize: 15.5),
          ),
          const SizedBox(height: 6),
          Text(
            item.body,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 10.5,
        ),
      ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'content':
        return Icons.menu_book_rounded;
      case 'update':
        return Icons.system_update_alt_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }

  String _labelForCategory(String category) {
    switch (category) {
      case 'content':
        return 'MATERI BARU';
      case 'update':
        return 'PEMBARUAN';
      default:
        return 'PENGUMUMAN';
    }
  }

  String _formatDate(DateTime date) {
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
    final m = months[(local.month - 1).clamp(0, 11)];
    return '${local.day} $m ${local.year}';
  }
}

