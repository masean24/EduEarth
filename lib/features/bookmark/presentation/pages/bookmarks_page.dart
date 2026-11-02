import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/common/empty_view.dart';
import '../../../../core/widgets/common/error_view.dart';
import '../../../../core/widgets/common/loading_view.dart';
import '../../../../core/widgets/common/material_card.dart';
import '../../../../core/widgets/common/plant_card.dart';
import '../../../../routes/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/bookmark_providers.dart';

/// Halaman Daftar Bookmark Pengguna (Materi & Pembangkit).
///
/// Menangani kondisi pengguna belum login dengan mengarahkan ke halaman Login,
/// serta menampilkan 3 state UI (`LoadingView`, `ErrorView`, `EmptyView`).
class BookmarksPage extends ConsumerWidget {
  const BookmarksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final bookmarksAsync = ref.watch(userBookmarksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmark Saya'),
      ),
      body: SafeArea(
        child: !isAuthenticated
            ? EmptyView(
                icon: Icons.lock_outline_rounded,
                title: 'Masuk untuk Melihat Bookmark',
                description:
                    'Simpan materi pembelajaran dan pembangkit favorit ke akun Anda agar dapat diakses kapan saja.',
                actionLabel: 'Masuk (Login)',
                onAction: () => context.push(RouteNames.loginPath),
              )
            : RefreshIndicator(
                color: AppColors.freshGreen,
                onRefresh: () async {
                  ref.invalidate(userBookmarksProvider);
                },
                child: bookmarksAsync.when(
                  loading: () => const LoadingView(
                    message: 'Memuat daftar bookmark Anda...',
                  ),
                  error: (error, _) => ErrorView(
                    message: error.toString(),
                    onRetry: () => ref.invalidate(userBookmarksProvider),
                  ),
                  data: (bookmarks) {
                    if (bookmarks.isEmpty) {
                      return EmptyView(
                        icon: Icons.bookmark_border_rounded,
                        title: 'Belum Ada Bookmark Tersimpan',
                        description:
                            'Ketuk ikon bookmark di halaman detail materi atau detail pembangkit untuk menyimpannya di sini.',
                        actionLabel: 'Jelajahi Materi',
                        onAction: () => context.go(RouteNames.learningPath),
                      );
                    }

                    final materialBookmarks = bookmarks
                        .where((b) => b.material != null)
                        .toList();
                    final plantBookmarks = bookmarks
                        .where((b) => b.plant != null)
                        .toList();

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                      children: [
                        if (materialBookmarks.isNotEmpty) ...[
                          Text(
                            'Materi Pembelajaran (${materialBookmarks.length})',
                            style: AppTextStyles.title,
                          ),
                          const SizedBox(height: 12),
                          ...materialBookmarks.map((b) {
                            final mat = b.material!;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: MaterialCard(
                                material: mat,
                                onTap: () => context.push(
                                  '/learning/material/${mat.slug}',
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                        ],
                        if (plantBookmarks.isNotEmpty) ...[
                          Text(
                            'Pembangkit Energi (${plantBookmarks.length})',
                            style: AppTextStyles.title,
                          ),
                          const SizedBox(height: 12),
                          ...plantBookmarks.map((b) {
                            final plant = b.plant!;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: PlantCard(
                                plant: plant,
                                onTap: () =>
                                    context.push('/plants/${plant.id}'),
                              ),
                            );
                          }),
                        ],
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }
}
